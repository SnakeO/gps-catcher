require 'test_helper'

class NewGl200DecoderTest < ActiveSupport::TestCase
  setup do
    @decoder = Gl200Decoder.new
    @external_id = "test-gl200-#{SecureRandom.hex(4)}"
  end

  # Example from the original decoder:
  # +RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,196.5,-97.147099,32.742800,20150526000805,,,,,,91,20150526000956,1291$

  def sample_fields
    [
      "02010D",           # protocol_version
      "867844001851958",  # esn
      "",                 # device_name
      "0",                # append_mask
      "0",                # report_type
      "1",                # num_points
      "2",                # gps_accuracy
      "0",                # speed
      "196",              # azimuth
      "196.5",            # altitude
      "-97.147099",       # longitude
      "32.742800",        # latitude
      "20150526000805",   # gps_time
      "",                 # mcc
      "",                 # mnc
      "",                 # lac
      "",                 # cell_id
      "0",                # odo_mileage
      "91",               # battery_percentage
      "20150526000956",   # send_time
      @external_id        # message_id (at end)
    ]
  end

  test "decodes position report with single point" do
    messages = @decoder.decode_position_report(sample_fields)

    assert messages.any?, "Should produce at least one message"
    sources = messages.map(&:source)

    assert_includes sources, 'location'
    assert_includes sources, 'battery'
  end

  test "extracts correct coordinates" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg
    lat, lng = location_msg.value.split(',').map(&:to_f)

    assert_in_delta 32.7428, lat, 0.001
    assert_in_delta(-97.147099, lng, 0.001)
  end

  test "extracts battery percentage" do
    messages = @decoder.decode_position_report(sample_fields)
    battery_msg = messages.find { |m| m.source == 'battery' }

    assert_not_nil battery_msg
    assert_equal '91', battery_msg.value
  end

  test "sets esn on messages" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_equal "867844001851958", location_msg.esn
  end

  test "sets occurred_at from GPS time" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg.occurred_at
    assert_equal 2015, location_msg.occurred_at.year
    assert_equal 5, location_msg.occurred_at.month
    assert_equal 26, location_msg.occurred_at.day
  end

  test "includes speed in meta" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert meta.key?('speed')
    assert_equal 0.0, meta['speed']
  end

  test "includes altitude in meta" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert meta.key?('altitude')
    assert_equal 196.5, meta['altitude']
  end

  test "calculates confidence from gps_accuracy" do
    messages = @decoder.decode_position_report(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert meta.key?('confidence')
    # gps_accuracy = 2, so confidence = (50-2)/50 = 0.96
    assert_in_delta 0.96, meta['confidence'], 0.01
  end

  test "handles multiple location points" do
    fields = [
      "02010D",           # protocol_version
      "867844001851958",  # esn
      "",                 # device_name
      "0",                # append_mask
      "0",                # report_type
      "2",                # num_points (2 points)
      # First point
      "2", "10", "180", "100.0", "-97.147099", "32.742800", "20150526000805",
      "", "", "", "", "1000",
      # Second point
      "3", "20", "90", "105.0", "-97.148", "32.743", "20150526000905",
      "", "", "", "", "1010",
      # Battery and message ID
      "85",
      @external_id
    ]

    messages = @decoder.decode_position_report(fields)
    location_msgs = messages.select { |m| m.source == 'location' }

    assert_equal 2, location_msgs.length, "Should have 2 location messages"
  end

  test "deduplicates identical messages" do
    fields1 = sample_fields
    fields2 = sample_fields.dup

    messages1 = @decoder.decode_position_report(fields1)
    messages1.each(&:save!)

    messages2 = @decoder.decode_position_report(fields2)
    location1 = messages1.find { |m| m.source == 'location' }
    location2 = messages2.find { |m| m.source == 'location' }

    assert location2.persisted?, "Should return existing message"
    assert_equal location1.id, location2.id
  end

  test "skips battery message when value is zero" do
    fields = sample_fields.dup
    # Battery is at index -3 (before send_time and message_id)
    fields[-3] = "0"  # Set battery to 0

    messages = @decoder.decode_position_report(fields)
    battery_msg = messages.find { |m| m.source == 'battery' }

    assert_nil battery_msg
  end

  test "handles missing GPS time gracefully" do
    fields = sample_fields.dup
    fields[12] = ""  # Clear GPS time

    messages = @decoder.decode_position_report(fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg.occurred_at
  end
end
