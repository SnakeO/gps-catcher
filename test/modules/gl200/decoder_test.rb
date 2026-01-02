require 'test_helper'

class Gl200DecoderTest < ActiveSupport::TestCase

  def setup
    @decoder = Gl200::Decoder.new
  end

  # ============================================
  # Position Report Parsing Tests
  # ============================================

  test "parses position report with single location point" do
    # Sample payload from code: +RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,196.5,-97.147099,32.742800,20150526000805,,,,,,91,20150526000956,1291$
    fields = [
      '02010D',        # protocol_version
      '867844001851958', # esn
      '',              # device_name
      '0',             # append_mask
      '0',             # report_type
      '1',             # num_points
      '2',             # gps_accuracy
      '-1',            # speed (can be -1 for invalid)
      '0',             # azimuth
      '196.5',         # altitude
      '-97.147099',    # longitude
      '32.742800',     # latitude
      '20150526000805', # gps_utc_time
      '',              # mcc
      '',              # mnc
      '',              # lac
      '',              # cell_id
      '',              # odo_mileage
      '91',            # battery_percentage
      '20150526000956', # send_time
      '1291'           # count_number (external_message_id)
    ]

    messages = @decoder.positionReport(fields.dup)

    assert messages.is_a?(Array), "Should return array of messages"
    assert messages.length >= 1, "Should return at least one message"
  end

  test "extracts ESN from position report" do
    fields = create_position_report_fields(esn: '867844001851958')

    @decoder.positionReport(fields)

    # Check that decoder captured ESN
    assert_equal '867844001851958', @decoder.instance_variable_get(:@esn)
  end

  test "extracts location message from position report" do
    fields = create_position_report_fields(
      latitude: '32.742800',
      longitude: '-97.147099'
    )

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    assert_not_nil location_msg, "Should include location message"
    assert_equal '32.742800,-97.147099', location_msg.value
  end

  test "extracts battery message from position report" do
    fields = create_position_report_fields(battery: '91')

    messages = @decoder.positionReport(fields)

    battery_msg = messages.find { |m| m.source == 'battery' }
    assert_not_nil battery_msg, "Should include battery message"
    assert_equal 91, battery_msg.value.to_i
  end

  test "handles multiple location points" do
    fields = [
      '02010D',        # protocol_version
      '867844001851958', # esn
      '',              # device_name
      '0',             # append_mask
      '0',             # report_type
      '2',             # num_points = 2
      # First point
      '2', '10.5', '90', '100.0', '-97.1', '32.7', '20150526000805', '', '', '', '', '',
      # Second point
      '3', '15.0', '180', '110.0', '-97.2', '32.8', '20150526001000', '', '', '', '', '',
      '85',            # battery
      '20150526001200', # send_time
      '1292'           # count_number
    ]

    messages = @decoder.positionReport(fields)

    location_msgs = messages.select { |m| m.source == 'location' }
    assert_equal 2, location_msgs.length, "Should have 2 location messages"
  end

  test "calculates confidence from GPS accuracy" do
    fields = create_position_report_fields(gps_accuracy: '10')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    meta = JSON.parse(location_msg.meta)

    # confidence = (50 - gps_accuracy) / 50.0 = (50 - 10) / 50 = 0.8
    assert_equal 0.8, meta['confidence']
  end

  test "includes speed in location meta" do
    fields = create_position_report_fields(speed: '65.5')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    meta = JSON.parse(location_msg.meta)

    assert_equal 65.5, meta['speed']
  end

  test "includes altitude in location meta" do
    fields = create_position_report_fields(altitude: '196.5')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    meta = JSON.parse(location_msg.meta)

    assert_equal 196.5, meta['altitude']
  end

  test "includes odometer in location meta" do
    fields = create_position_report_fields(odometer: '12345')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    meta = JSON.parse(location_msg.meta)

    assert_equal '12345', meta['odometer']
  end

  test "parses occurred_at timestamp correctly" do
    fields = create_position_report_fields(gps_time: '20150526000805')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    assert_not_nil location_msg.occurred_at
    assert_equal 2015, location_msg.occurred_at.year
    assert_equal 5, location_msg.occurred_at.month
    assert_equal 26, location_msg.occurred_at.day
  end

  # ============================================
  # Edge Cases
  # ============================================

  test "handles negative speed value" do
    fields = create_position_report_fields(speed: '-1')

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    meta = JSON.parse(location_msg.meta)
    assert_equal(-1.0, meta['speed'])
  end

  test "handles empty device name" do
    fields = create_position_report_fields(device_name: '')

    messages = @decoder.positionReport(fields)

    assert messages.length >= 1
  end

  test "handles zero battery percentage" do
    fields = create_position_report_fields(battery: '0')

    messages = @decoder.positionReport(fields)

    battery_msg = messages.find { |m| m.source == 'battery' }
    assert_equal 0, battery_msg.value.to_i
  end

  test "handles maximum battery percentage" do
    fields = create_position_report_fields(battery: '100')

    messages = @decoder.positionReport(fields)

    battery_msg = messages.find { |m| m.source == 'battery' }
    assert_equal 100, battery_msg.value.to_i
  end

  # ============================================
  # Message Deduplication Tests
  # ============================================

  test "returns existing location message if duplicate" do
    external_message_id = 'test-dedup-gl200'
    lat = '32.742800'
    lng = '-97.147099'
    meta = { confidence: 0.96, speed: 0.0, altitude: 196.5, gps_accuracy: 2, odometer: '' }

    # Create existing message
    existing = ParsedMessage.create!(
      source: 'location',
      value: "#{lat},#{lng}",
      meta: meta.to_json,
      esn: '867844001851958',
      message_id: ParsedMessage.makeHashID(external_message_id, 'location', "#{lat},#{lng}", meta.to_json)
    )

    fields = create_position_report_fields(
      latitude: lat,
      longitude: lng,
      external_message_id: external_message_id
    )

    messages = @decoder.positionReport(fields)

    location_msg = messages.find { |m| m.source == 'location' }
    assert_equal existing.id, location_msg.id
  end

  private

  def create_position_report_fields(options = {})
    [
      options[:protocol_version] || '02010D',
      options[:esn] || '867844001851958',
      options[:device_name] || '',
      options[:append_mask] || '0',
      options[:report_type] || '0',
      options[:num_points] || '1',
      options[:gps_accuracy] || '2',
      options[:speed] || '0',
      options[:azimuth] || '0',
      options[:altitude] || '196.5',
      options[:longitude] || '-97.147099',
      options[:latitude] || '32.742800',
      options[:gps_time] || '20150526000805',
      options[:mcc] || '',
      options[:mnc] || '',
      options[:lac] || '',
      options[:cell_id] || '',
      options[:odometer] || '',
      options[:battery] || '91',
      options[:send_time] || '20150526000956',
      options[:external_message_id] || '1291'
    ]
  end
end
