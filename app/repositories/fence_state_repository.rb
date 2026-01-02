# Repository for FenceState queries and operations
# Encapsulates database access patterns for geofence state tracking
class FenceStateRepository
  # Find the most recent fence state for an ESN and geofence
  def last_state(esn:, geofence_id:)
    FenceState
      .where(esn: esn, geofence_id: geofence_id)
      .order(occurred_at: :desc)
      .first
  end

  # Check if a location message has already been processed for a fence
  def already_checked?(esn:, geofence_id:, occurred_at:)
    last = last_state(esn: esn, geofence_id: geofence_id)
    last && last.occurred_at > occurred_at
  end

  # Create a new fence state
  def create(geofence:, location_msg:, state:)
    fence_state = FenceState.new(
      geofence: geofence,
      location_msg: location_msg,
      occurred_at: location_msg.occurred_at,
      state: state,
      esn: location_msg.esn
    )
    fence_state.save!
    fence_state
  end

  # Build a fence state without saving
  def build(geofence:, location_msg:, inside:)
    FenceState.new(
      geofence: geofence,
      location_msg: location_msg,
      occurred_at: location_msg.occurred_at,
      state: inside ? 'i' : 'o',
      esn: location_msg.esn
    )
  end

  # Create an initial "unknown" fence state for tracking purposes
  def build_unknown_state
    state = FenceState.new
    state.state = nil
    state
  end

  # Determine if a state transition occurred
  # Returns :entered, :exited, or nil
  def detect_transition(previous_state:, current_state:)
    prev = previous_state&.state
    curr = current_state.state

    return nil if prev == curr

    if prev == 'o' && curr == 'i'
      :entered
    elsif prev == 'i' && curr == 'o'
      :exited
    else
      # First state or unknown transition
      nil
    end
  end

  # Get all fence states for an ESN, ordered by time
  def states_for_esn(esn:, limit: nil)
    query = FenceState.where(esn: esn).order(occurred_at: :desc)
    query = query.limit(limit) if limit
    query
  end

  # Get states for a specific geofence
  def states_for_geofence(geofence_id:, limit: nil)
    query = FenceState.where(geofence_id: geofence_id).order(occurred_at: :desc)
    query = query.limit(limit) if limit
    query
  end
end
