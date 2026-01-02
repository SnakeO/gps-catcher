# Service for checking location messages against geofences
# Extracts the complex geofence checking algorithm from the controller
class GeofenceCheckService
  attr_reader :messages_processed, :alerts_created

  def initialize(fence_state_repository: FenceStateRepository.new)
    @fence_state_repository = fence_state_repository
    @messages_processed = 0
    @alerts_created = 0
  end

  # Process all new location messages since the last check
  # Returns the count of messages processed
  def call
    last_checked_setting = Setting.where(key: 'last_location_msg_checked').first
    start_id = last_checked_setting.value.to_i

    LocationMsg.where('id > ?', start_id).order(occurred_at: :asc).find_each do |message|
      process_message(message)
      last_checked_setting.value = message.id
      @messages_processed += 1
    end

    last_checked_setting.save
    @messages_processed
  end

  # Process a single location message against all its geofences
  def process_message(message)
    Geofence.where(esn: message.esn).find_each do |fence|
      check_fence(message, fence)
    rescue StandardError => e
      Rails.logger.error("Error checking geofence #{fence.id} for message #{message.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end

  private

  def check_fence(message, fence)
    return if skip_fence?(message, fence)

    last_state = @fence_state_repository.last_state(
      esn: message.esn,
      geofence_id: fence.id
    )

    # Skip if already checked past this point
    return if last_state && last_state.occurred_at > message.occurred_at

    is_inside = fence.contains(message.point.y, message.point.x)
    current_state = build_current_state(fence, message, is_inside)

    # Handle first state (no previous state)
    if last_state.nil?
      last_state = @fence_state_repository.build_unknown_state
    end

    # No change in state? Skip
    return if current_state.state == last_state.state

    # Check for transitions and create alerts
    transition = @fence_state_repository.detect_transition(
      previous_state: last_state,
      current_state: current_state
    )

    current_state.save!
    create_alert_if_needed(fence, current_state, transition, last_state)
  end

  def skip_fence?(message, fence)
    # Skip deleted fences
    return true if fence.deleted_at.present?

    # Skip if fence didn't exist when this location occurred
    return true if fence.created_at > message.occurred_at

    false
  end

  def build_current_state(fence, message, is_inside)
    FenceState.new(
      geofence: fence,
      location_msg: message,
      occurred_at: message.occurred_at,
      state: is_inside ? 'i' : 'o',
      esn: message.esn
    )
  end

  def create_alert_if_needed(fence, current_state, transition, last_state)
    return unless should_alert?(fence, transition, last_state)

    log_alert(current_state, transition, last_state)

    fence_alert = FenceAlert.create!(
      processed_stage: 1,
      geofence: current_state.geofence,
      webhook_url: current_state.geofence.webhook_url,
      fence_state: current_state
    )

    fence.increment!(:num_alerts_sent)
    FenceAlertWorker.perform_async(fence_alert.id)
    @alerts_created += 1
  end

  def should_alert?(fence, transition, last_state)
    return false if transition.nil?
    return false if last_state.state.nil?

    case transition
    when :entered
      %w[i b].include?(fence.alert_type)
    when :exited
      %w[o b].include?(fence.alert_type)
    else
      false
    end
  end

  def log_alert(current_state, transition, last_state)
    action = transition == :entered ? 'ENTERED' : 'EXITED'
    puts "ALERT - #{current_state.esn} #{action} FENCE #{current_state.geofence_id} @ #{current_state.occurred_at}"
    puts "\tlast_fence_state: #{last_state.state} @ #{last_state.occurred_at}"
  end
end
