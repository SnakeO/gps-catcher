require 'test_helper'

class FenceStateRepositoryTest < ActiveSupport::TestCase
  setup do
    @repo = FenceStateRepository.new
    @esn = "test-esn-#{SecureRandom.hex(4)}"

    # Create a geofence for testing (no name column in schema)
    @geofence = Geofence.create!(
      esn: @esn,
      alert_type: 'b',
      created_at: 1.day.ago
    )

    # Create a location message for testing
    @location_msg = LocationMsg.create!(
      esn: @esn,
      point: "POINT(-97.1471 32.7428)",
      occurred_at: Time.now.utc
    )
  end

  test "last_state returns nil when no states exist" do
    result = @repo.last_state(esn: @esn, geofence_id: @geofence.id)
    assert_nil result
  end

  test "last_state returns most recent state" do
    # Create two states
    older_state = FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: @location_msg,
      state: 'o',
      occurred_at: 2.hours.ago
    )

    newer_location = LocationMsg.create!(
      esn: @esn,
      point: "POINT(-97.1471 32.7428)",
      occurred_at: 1.hour.ago
    )

    newer_state = FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: newer_location,
      state: 'i',
      occurred_at: 1.hour.ago
    )

    result = @repo.last_state(esn: @esn, geofence_id: @geofence.id)

    assert_equal newer_state.id, result.id
    assert_equal 'i', result.state
  end

  test "already_checked? returns false when no states exist" do
    result = @repo.already_checked?(
      esn: @esn,
      geofence_id: @geofence.id,
      occurred_at: Time.now.utc
    )
    refute result
  end

  test "already_checked? returns true when state exists after given time" do
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: @location_msg,
      state: 'i',
      occurred_at: Time.now.utc
    )

    result = @repo.already_checked?(
      esn: @esn,
      geofence_id: @geofence.id,
      occurred_at: 1.hour.ago
    )

    assert result
  end

  test "already_checked? returns false when state exists before given time" do
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: @location_msg,
      state: 'i',
      occurred_at: 2.hours.ago
    )

    result = @repo.already_checked?(
      esn: @esn,
      geofence_id: @geofence.id,
      occurred_at: 1.hour.ago
    )

    refute result
  end

  test "build creates unsaved fence state" do
    state = @repo.build(
      geofence: @geofence,
      location_msg: @location_msg,
      inside: true
    )

    refute state.persisted?
    assert_equal 'i', state.state
    assert_equal @esn, state.esn
    assert_equal @geofence.id, state.geofence_id
  end

  test "build sets state to 'o' when outside" do
    state = @repo.build(
      geofence: @geofence,
      location_msg: @location_msg,
      inside: false
    )

    assert_equal 'o', state.state
  end

  test "build_unknown_state creates state with nil state" do
    state = @repo.build_unknown_state

    assert_nil state.state
    refute state.persisted?
  end

  test "create saves fence state to database" do
    state = @repo.create(
      geofence: @geofence,
      location_msg: @location_msg,
      state: 'i'
    )

    assert state.persisted?
    assert_equal 'i', state.state
    assert_equal @esn, state.esn
  end

  test "detect_transition returns nil for same state" do
    prev = FenceState.new(state: 'i')
    curr = FenceState.new(state: 'i')

    result = @repo.detect_transition(previous_state: prev, current_state: curr)

    assert_nil result
  end

  test "detect_transition returns :entered for o to i" do
    prev = FenceState.new(state: 'o')
    curr = FenceState.new(state: 'i')

    result = @repo.detect_transition(previous_state: prev, current_state: curr)

    assert_equal :entered, result
  end

  test "detect_transition returns :exited for i to o" do
    prev = FenceState.new(state: 'i')
    curr = FenceState.new(state: 'o')

    result = @repo.detect_transition(previous_state: prev, current_state: curr)

    assert_equal :exited, result
  end

  test "detect_transition returns nil when previous state is nil object" do
    prev = nil
    curr = FenceState.new(state: 'i')

    result = @repo.detect_transition(previous_state: prev, current_state: curr)

    assert_nil result
  end

  test "detect_transition returns nil for unknown previous state" do
    prev = @repo.build_unknown_state
    curr = FenceState.new(state: 'i')

    result = @repo.detect_transition(previous_state: prev, current_state: curr)

    assert_nil result
  end

  test "states_for_esn returns states ordered by time" do
    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: @location_msg,
      state: 'i',
      occurred_at: 2.hours.ago
    )

    newer_location = LocationMsg.create!(
      esn: @esn,
      point: "POINT(-97.1471 32.7428)",
      occurred_at: 1.hour.ago
    )

    FenceState.create!(
      esn: @esn,
      geofence: @geofence,
      location_msg: newer_location,
      state: 'o',
      occurred_at: 1.hour.ago
    )

    states = @repo.states_for_esn(esn: @esn)

    assert_equal 2, states.count
    assert_equal 'o', states.first.state  # Most recent first
  end

  test "states_for_esn respects limit" do
    3.times do |i|
      location = LocationMsg.create!(
        esn: @esn,
        point: "POINT(-97.1471 32.7428)",
        occurred_at: i.hours.ago
      )
      FenceState.create!(
        esn: @esn,
        geofence: @geofence,
        location_msg: location,
        state: i.even? ? 'i' : 'o',
        occurred_at: i.hours.ago
      )
    end

    states = @repo.states_for_esn(esn: @esn, limit: 2)

    assert_equal 2, states.count
  end
end
