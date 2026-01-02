require 'test_helper'

class ParsedMessageFactoryTest < ActiveSupport::TestCase
  setup do
    @external_message_id = "test-factory-#{SecureRandom.hex(4)}"
  end

  # Location messages
  test "creates location message with coordinates" do
    coords = Coordinates.new(32.7428, -97.1471)
    message = ParsedMessageFactory.location(
      external_message_id: @external_message_id,
      coordinates: coords,
      meta: { confidence: 0.95 }
    )

    assert_equal 'location', message.source
    assert_equal '32.7428,-97.1471', message.value
    assert_includes message.meta, 'confidence'
    assert message.message_id.present?
  end

  test "returns existing location message if duplicate" do
    coords = Coordinates.new(32.7428, -97.1471)

    message1 = ParsedMessageFactory.location(
      external_message_id: @external_message_id,
      coordinates: coords
    )
    message1.save!

    message2 = ParsedMessageFactory.location(
      external_message_id: @external_message_id,
      coordinates: coords
    )

    assert_equal message1.id, message2.id
  end

  # Battery messages
  test "creates good battery message" do
    message = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: true
    )

    assert_equal 'battery', message.source
    assert_equal 'g', message.value
  end

  test "creates bad battery message" do
    message = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: false
    )

    assert_equal 'battery', message.source
    assert_equal 'b', message.value
  end

  # Power messages
  test "creates power on message" do
    message = ParsedMessageFactory.power(
      external_message_id: @external_message_id,
      state: 'on'
    )

    assert_equal 'powered', message.source
    assert_equal 'on', message.value
  end

  # Motion messages
  test "creates in motion message" do
    message = ParsedMessageFactory.motion(
      external_message_id: @external_message_id,
      in_motion: 1
    )

    assert_equal 'is_in_motion', message.source
    assert_equal '1', message.value
  end

  # Info messages
  test "creates generic info message" do
    message = ParsedMessageFactory.info(
      external_message_id: @external_message_id,
      source: 'custom',
      value: 'custom_value',
      meta: { key: 'value' }
    )

    assert_equal 'custom', message.source
    assert_equal 'custom_value', message.value
    assert_includes message.meta, 'key'
  end

  # Deduplication
  test "deduplicates messages with same hash" do
    message1 = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: true
    )
    message1.save!

    message2 = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: true
    )

    assert_equal message1.id, message2.id
    assert message2.persisted?
  end

  test "creates new message for different values" do
    message1 = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: true
    )
    message1.save!

    message2 = ParsedMessageFactory.battery(
      external_message_id: @external_message_id,
      good: false
    )

    refute_equal message1.message_id, message2.message_id
    refute message2.persisted?
  end
end
