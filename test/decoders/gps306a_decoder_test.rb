require 'test_helper'

class Gps306aDecoderTest < ActiveSupport::TestCase
  setup do
    @decoder = Gps306aDecoder.new
  end

  # Example from the original decoder:
  # imei:359710049084651,tracker,150828170049,,F,090049.000,A,3244.5761,N,09708.8238,W,0.00,266.92,,0,0,,,;

  def sample_fields
    [
      "imei:359710049084651",  # IMEI
      "tracker",               # device name
      "150828170049",          # date/time YYMMDDHHMMSS
      "",                      # empty
      "F",                     # fix marker
      "090049.000",            # external message ID (time)
      "A",                     # valid fix marker
      "3244.5761",             # latitude DDMM.MMMM
      "N",                     # hemisphere
      "09708.8238",            # longitude DDDMM.MMMM
      "W",                     # hemisphere
      "0.00",                  # speed/unknown
      "266.92",                # azimuth
      "",                      # empty
      "0",                     # unused
      "0",                     # unused
      "",                      # empty
      "",                      # empty
      ""                       # empty
    ]
  end

  test "decodes location message" do
    messages = @decoder.decode_location_message(sample_fields)

    assert messages.any?, "Should produce at least one message"
    sources = messages.map(&:source)
    assert_includes sources, 'location'
  end

  test "extracts IMEI as ESN" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_equal "359710049084651", location_msg.esn
  end

  test "converts NMEA latitude correctly" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    lat, _ = location_msg.value.split(',').map(&:to_f)

    # 3244.5761 N = 32 degrees + 44.5761/60 minutes = 32.7429...
    assert_in_delta 32.7429, lat, 0.001
  end

  test "converts NMEA longitude correctly" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    _, lng = location_msg.value.split(',').map(&:to_f)

    # 09708.8238 W = -(97 degrees + 8.8238/60 minutes) = -97.147...
    assert_in_delta(-97.147, lng, 0.001)
  end

  test "handles southern hemisphere latitude" do
    fields = sample_fields.dup
    fields[8] = "S"  # Change to South

    messages = @decoder.decode_location_message(fields)
    location_msg = messages.find { |m| m.source == 'location' }

    lat, _ = location_msg.value.split(',').map(&:to_f)
    assert lat < 0, "Southern latitude should be negative"
  end

  test "handles eastern hemisphere longitude" do
    fields = sample_fields.dup
    fields[10] = "E"  # Change to East

    messages = @decoder.decode_location_message(fields)
    location_msg = messages.find { |m| m.source == 'location' }

    _, lng = location_msg.value.split(',').map(&:to_f)
    assert lng > 0, "Eastern longitude should be positive"
  end

  test "extracts occurred_at from date string" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg.occurred_at
    assert_equal 2015, location_msg.occurred_at.year
    assert_equal 8, location_msg.occurred_at.month
    assert_equal 28, location_msg.occurred_at.day
  end

  test "includes azimuth in meta" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert_equal "266.92", meta['azimuth']
  end

  test "uses time field as external message ID" do
    messages = @decoder.decode_location_message(sample_fields)
    location_msg = messages.find { |m| m.source == 'location' }

    # Message ID should be derived from the external_message_id
    assert location_msg.message_id.present?
  end

  test "deduplicates identical messages" do
    fields1 = sample_fields
    fields2 = sample_fields.dup

    messages1 = @decoder.decode_location_message(fields1)
    messages1.each(&:save!)

    messages2 = @decoder.decode_location_message(fields2)
    location1 = messages1.find { |m| m.source == 'location' }
    location2 = messages2.find { |m| m.source == 'location' }

    assert location2.persisted?
    assert_equal location1.id, location2.id
  end

  test "handles different IMEI format" do
    fields = sample_fields.dup
    fields[0] = "imei:123456789012345"

    messages = @decoder.decode_location_message(fields)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_equal "123456789012345", location_msg.esn
  end
end
