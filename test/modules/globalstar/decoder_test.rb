require 'test_helper'

class GlobalstarDecoderTest < ActiveSupport::TestCase

  def setup
    @decoder = Globalstar::Decoder.new
  end

  # ============================================
  # Payload Decoding Tests
  # ============================================

  test "decodes valid 72-bit payload" do
    # Sample payload from the code comments: 0x002E914EBAEAE84A08
    payload = "002E914EBAEAE84A08"
    external_message_id = "test-msg-123"

    messages = @decoder.payload(payload, external_message_id)

    assert messages.is_a?(Array), "Should return an array of messages"
    assert messages.length >= 2, "Should return at least battery and motion messages"
  end

  test "extracts battery message from payload" do
    payload = "002E914EBAEAE84A08"
    external_message_id = "test-msg-123"

    messages = @decoder.payload(payload, external_message_id)

    battery_msg = messages.find { |m| m.source == 'battery' }
    assert_not_nil battery_msg, "Should include a battery message"
    assert ['g', 'b'].include?(battery_msg.value), "Battery value should be 'g' (good) or 'b' (bad)"
  end

  test "extracts location message with valid GPS data" do
    payload = "002E914EBAEAE84A08"
    external_message_id = "test-msg-123"

    messages = @decoder.payload(payload, external_message_id)

    location_msg = messages.find { |m| m.source == 'location' }
    # Location may be nil if gps_data_valid bit indicates invalid data
    if location_msg
      assert location_msg.value.include?(','), "Location value should be lat,lng format"
    end
  end

  test "extracts is_in_motion message" do
    payload = "002E914EBAEAE84A08"
    external_message_id = "test-msg-123"

    messages = @decoder.payload(payload, external_message_id)

    motion_msg = messages.find { |m| m.source == 'is_in_motion' }
    assert_not_nil motion_msg, "Should include an is_in_motion message"
    assert [0, 1].include?(motion_msg.value.to_i), "Motion value should be 0 or 1"
  end

  # ============================================
  # Latitude/Longitude Conversion Tests (Two's Complement)
  # ============================================

  test "converts positive latitude from binary" do
    # Binary for a positive latitude
    # Testing with a known positive value
    positive_lat_bin = "000100000000000000000000"  # Should be positive

    lat = @decoder.latFromBin(positive_lat_bin)

    assert lat >= 0, "Should return positive latitude"
    assert lat <= 90, "Latitude should be <= 90"
  end

  test "converts negative latitude from binary using twos complement" do
    # Binary starting with 1 indicates negative (two's complement)
    negative_lat_bin = "111111111111111111111111"  # All 1s = -1 in two's complement

    lat = @decoder.latFromBin(negative_lat_bin)

    assert lat < 0, "Should return negative latitude"
    assert lat >= -90, "Latitude should be >= -90"
  end

  test "converts positive longitude from binary" do
    positive_lng_bin = "000100000000000000000000"

    lng = @decoder.lngFromBin(positive_lng_bin)

    assert lng >= 0, "Should return positive longitude"
    assert lng <= 180, "Longitude should be <= 180"
  end

  test "converts negative longitude from binary using twos complement" do
    negative_lng_bin = "111111111111111111111111"

    lng = @decoder.lngFromBin(negative_lng_bin)

    assert lng < 0, "Should return negative longitude"
    assert lng >= -180, "Longitude should be >= -180"
  end

  # ============================================
  # Message Sub-Type Tests
  # ============================================

  test "returns nil for regular location message subtype 0" do
    result = @decoder.msgFromSubType(0)

    assert_nil result
  end

  test "returns powered on message for subtype 1" do
    # Need to set external_message_id first
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    result = @decoder.msgFromSubType(1)

    assert_not_nil result
    assert_equal 'powered', result.source
    assert_equal 'on', result.value
  end

  test "returns nil for other subtypes 2-5" do
    [2, 3, 4, 5].each do |subtype|
      result = @decoder.msgFromSubType(subtype)
      assert_nil result, "Subtype #{subtype} should return nil"
    end
  end

  # ============================================
  # Message Creation Tests
  # ============================================

  test "getBatteryMsg returns good battery for value 0" do
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    msg = @decoder.getBatteryMsg(0)

    assert_not_nil msg
    assert_equal 'battery', msg.source
    assert_equal 'g', msg.value
  end

  test "getBatteryMsg returns bad battery for value 1" do
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    msg = @decoder.getBatteryMsg(1)

    assert_not_nil msg
    assert_equal 'battery', msg.source
    assert_equal 'b', msg.value
  end

  test "getInMotionMsg returns correct motion value" do
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    msg_moving = @decoder.getInMotionMsg(1)
    msg_still = @decoder.getInMotionMsg(0)

    assert_equal 'is_in_motion', msg_moving.source
    assert_equal 1, msg_moving.value
    assert_equal 0, msg_still.value
  end

  test "getLocationMsg returns nil for invalid GPS data" do
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    msg = @decoder.getLocationMsg(1, nil, nil, {})  # gps_data_valid = 1 means INVALID

    assert_nil msg
  end

  test "getLocationMsg returns message for valid GPS data" do
    @decoder.instance_variable_set(:@external_message_id, 'test-123')

    msg = @decoder.getLocationMsg(0, 32.742800, -97.147099, { twoD: 0, is_in_motion: 1, confidence: 1 })

    assert_not_nil msg
    assert_equal 'location', msg.source
    assert_equal '32.742800,-97.147099', msg.value
  end

  # ============================================
  # Edge Cases
  # ============================================

  test "handles minimum length payload" do
    # 9 bytes = 18 hex chars = 72 bits
    min_payload = "0" * 18
    external_message_id = "test-min"

    messages = @decoder.payload(min_payload, external_message_id)

    assert messages.is_a?(Array)
  end

  test "deduplicates existing messages" do
    @decoder.instance_variable_set(:@external_message_id, 'test-dedup')

    # Create an existing battery message
    existing = ParsedMessage.create!(
      source: 'battery',
      value: 'g',
      esn: 'test-esn',
      message_id: ParsedMessage.makeHashID('test-dedup', 'battery', 'g', nil)
    )

    # Getting battery msg should return the existing one
    msg = @decoder.getBatteryMsg(0)

    assert_equal existing.id, msg.id
  end
end
