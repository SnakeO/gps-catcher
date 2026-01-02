require 'test_helper'

# Test subclass that exposes protected methods for testing
class TestDecoder < BaseDecoder
  public :set_external_message_id, :set_esn, :set_occurred_at,
         :build_location_message, :build_battery_message,
         :build_battery_percentage_message, :build_power_message,
         :build_motion_message, :build_info_message,
         :external_message_id, :esn, :occurred_at
end

class BaseDecoderTest < ActiveSupport::TestCase
  setup do
    @decoder = TestDecoder.new
    @external_id = "test-decoder-#{SecureRandom.hex(4)}"
    @esn = "0-1234567"
    @occurred_at = Time.utc(2024, 1, 15, 10, 30, 0)

    @decoder.set_external_message_id(@external_id)
    @decoder.set_esn(@esn)
    @decoder.set_occurred_at(@occurred_at)
  end

  # State management
  test "stores external_message_id" do
    assert_equal @external_id, @decoder.external_message_id
  end

  test "stores esn" do
    assert_equal @esn, @decoder.esn
  end

  test "stores occurred_at as UTC" do
    assert_equal @occurred_at, @decoder.occurred_at
    assert @decoder.occurred_at.utc?
  end

  test "parses occurred_at from string" do
    @decoder.set_occurred_at("2024-01-15 10:30:00")
    assert_instance_of Time, @decoder.occurred_at
  end

  # Location messages
  test "builds location message with valid coordinates" do
    message = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471,
      meta: { confidence: 0.95 }
    )

    assert_not_nil message
    assert_equal 'location', message.source
    assert_equal '32.7428,-97.1471', message.value
    assert_equal @esn, message.esn
    assert_equal @occurred_at, message.occurred_at
    assert message.message_id.present?
  end

  test "returns nil for invalid coordinates" do
    message = @decoder.build_location_message(
      latitude: 0.0,
      longitude: 0.0
    )

    assert_nil message
  end

  test "returns nil for out of range coordinates" do
    message = @decoder.build_location_message(
      latitude: 91,
      longitude: 0
    )

    assert_nil message
  end

  # Battery messages
  test "builds good battery message with boolean true" do
    message = @decoder.build_battery_message(good: true)

    assert_equal 'battery', message.source
    assert_equal 'g', message.value
  end

  test "builds bad battery message with boolean false" do
    message = @decoder.build_battery_message(good: false)

    assert_equal 'battery', message.source
    assert_equal 'b', message.value
  end

  test "builds good battery message with string GOOD" do
    message = @decoder.build_battery_message(good: 'GOOD')

    assert_equal 'g', message.value
  end

  test "builds bad battery message with string LOW" do
    message = @decoder.build_battery_message(good: 'LOW')

    assert_equal 'b', message.value
  end

  test "interprets high percentage as good battery" do
    message = @decoder.build_battery_message(good: 75)

    assert_equal 'g', message.value
  end

  test "interprets low percentage as bad battery" do
    message = @decoder.build_battery_message(good: 25)

    assert_equal 'b', message.value
  end

  # Battery percentage messages
  test "builds battery percentage message" do
    message = @decoder.build_battery_percentage_message(percentage: 85)

    assert_equal 'battery', message.source
    assert_equal '85', message.value
  end

  # Power messages
  test "builds power on message" do
    message = @decoder.build_power_message(state: 'on')

    assert_equal 'powered', message.source
    assert_equal 'on', message.value
  end

  test "builds power off message" do
    message = @decoder.build_power_message(state: 'off')

    assert_equal 'powered', message.source
    assert_equal 'off', message.value
  end

  # Motion messages
  test "builds motion message with integer" do
    message = @decoder.build_motion_message(in_motion: 1)

    assert_equal 'is_in_motion', message.source
    assert_equal '1', message.value
  end

  test "builds motion message with boolean true" do
    message = @decoder.build_motion_message(in_motion: true)

    assert_equal 'is_in_motion', message.source
    assert_equal '1', message.value
  end

  test "builds motion message with boolean false" do
    message = @decoder.build_motion_message(in_motion: false)

    assert_equal 'is_in_motion', message.source
    assert_equal '0', message.value
  end

  # Info messages
  test "builds generic info message" do
    message = @decoder.build_info_message(
      source: 'custom_source',
      value: 'custom_value',
      meta: { key: 'data' }
    )

    assert_equal 'custom_source', message.source
    assert_equal 'custom_value', message.value
    assert_includes message.meta, 'key'
  end

  # Common attributes
  test "applies esn to new messages" do
    message = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )

    assert_equal @esn, message.esn
  end

  test "applies occurred_at to new messages" do
    message = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )

    assert_equal @occurred_at, message.occurred_at
  end

  # Deduplication
  test "returns existing message if duplicate" do
    message1 = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )
    message1.save!

    message2 = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )

    assert_equal message1.id, message2.id
    assert message2.persisted?
  end

  test "does not overwrite attributes on persisted message" do
    message1 = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )
    original_esn = message1.esn
    message1.save!

    # Change the decoder's esn
    @decoder.set_esn("different-esn")

    message2 = @decoder.build_location_message(
      latitude: 32.7428,
      longitude: -97.1471
    )

    # Should return the same persisted message with original attributes
    assert_equal message1.id, message2.id
    assert_equal original_esn, message2.esn
  end
end
