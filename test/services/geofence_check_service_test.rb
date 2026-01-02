require 'test_helper'

class GeofenceCheckServiceTest < ActiveSupport::TestCase
  setup do
    @esn = "test-esn-#{SecureRandom.hex(4)}"

    # Create or find the setting
    @setting = Setting.find_or_create_by!(key: 'last_location_msg_checked') do |s|
      s.value = '0'
    end
    @setting.update!(value: '0')

    # Create a geofence
    @geofence = Geofence.create!(
      esn: @esn,
      alert_type: 'b',  # Both enter and exit alerts
      created_at: 1.week.ago
    )

    @service = GeofenceCheckService.new
  end

  test "initializes with zero counts" do
    assert_equal 0, @service.messages_processed
    assert_equal 0, @service.alerts_created
  end

  test "processes new location messages" do
    # Mock FenceAlertWorker
    FenceAlertWorker.stubs(:perform_async)

    # Create a location message
    create_location_message(occurred_at: 1.hour.ago)

    result = @service.call

    assert_equal 1, result
    assert_equal 1, @service.messages_processed
  end

  test "updates last_location_msg_checked setting" do
    FenceAlertWorker.stubs(:perform_async)

    msg = create_location_message(occurred_at: 1.hour.ago)

    @service.call

    @setting.reload
    assert_equal msg.id.to_s, @setting.value
  end

  test "skips deleted geofences" do
    FenceAlertWorker.stubs(:perform_async)

    @geofence.update!(deleted_at: Time.now)
    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    # No fence states should be created
    assert_equal 0, FenceState.where(esn: @esn).count
  end

  test "skips geofences created after the message" do
    FenceAlertWorker.stubs(:perform_async)

    @geofence.update!(created_at: Time.now)
    create_location_message(occurred_at: 1.week.ago)

    @service.call

    # No fence states should be created
    assert_equal 0, FenceState.where(esn: @esn).count
  end

  test "creates fence state for first message" do
    FenceAlertWorker.stubs(:perform_async)

    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    assert_equal 1, FenceState.where(esn: @esn).count
  end

  test "does not create alert for first message (unknown previous state)" do
    FenceAlertWorker.stubs(:perform_async)

    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    # No alerts created for first state
    assert_equal 0, @service.alerts_created
    assert_equal 0, FenceAlert.count
  end

  test "creates alert when entering fence" do
    FenceAlertWorker.expects(:perform_async).once

    # Create first message - outside the fence
    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'o',  # Outside
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    # Mock ALL Geofence instances to return true (inside)
    Geofence.any_instance.stubs(:contains).returns(true)

    # Create second message - inside the fence
    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    assert_equal 1, @service.alerts_created
    assert_equal 1, FenceAlert.count
  end

  test "creates alert when exiting fence" do
    FenceAlertWorker.expects(:perform_async).once

    # Create first message - inside the fence
    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'i',  # Inside
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    # Mock to return false (outside)
    Geofence.any_instance.stubs(:contains).returns(false)

    # Create second message - outside the fence
    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    assert_equal 1, @service.alerts_created
  end

  test "does not create alert when state unchanged" do
    FenceAlertWorker.expects(:perform_async).never

    # Create first message - outside
    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'o',
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    # Mock still outside
    Geofence.any_instance.stubs(:contains).returns(false)

    # Create second message - still outside
    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    assert_equal 0, @service.alerts_created
  end

  test "respects alert_type for enter-only fence" do
    @geofence.update!(alert_type: 'i')  # Enter only
    FenceAlertWorker.expects(:perform_async).never

    # Start inside
    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'i',
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    # Mock exit (outside)
    Geofence.any_instance.stubs(:contains).returns(false)

    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    # Should not alert on exit for enter-only fence
    assert_equal 0, @service.alerts_created
  end

  test "respects alert_type for exit-only fence" do
    @geofence.update!(alert_type: 'o')  # Exit only
    FenceAlertWorker.expects(:perform_async).never

    # Start outside
    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'o',
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    # Mock enter (inside)
    Geofence.any_instance.stubs(:contains).returns(true)

    create_location_message(occurred_at: 1.hour.ago)

    @service.call

    # Should not alert on enter for exit-only fence
    assert_equal 0, @service.alerts_created
  end

  test "increments num_alerts_sent on geofence" do
    FenceAlertWorker.stubs(:perform_async)

    msg1 = create_location_message(occurred_at: 2.hours.ago)
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: msg1,
      state: 'o',
      occurred_at: msg1.occurred_at
    )
    @setting.update!(value: msg1.id.to_s)

    Geofence.any_instance.stubs(:contains).returns(true)
    create_location_message(occurred_at: 1.hour.ago)

    initial_count = @geofence.num_alerts_sent

    @service.call

    @geofence.reload
    assert_equal initial_count + 1, @geofence.num_alerts_sent
  end

  private

  def create_location_message(occurred_at:)
    LocationMsg.create!(
      esn: @esn,
      point: "POINT(-97.1471 32.7428)",
      occurred_at: occurred_at
    )
  end
end
