require 'test_helper'

class SpotTraceDecoderTest < ActiveSupport::TestCase
  setup do
    @decoder = SpotTraceDecoder.new
  end

  def sample_xml
    <<~XML
      <message>
        <id>399196236</id>
        <esn>0-2554023</esn>
        <esnName>SPOT 1</esnName>
        <messageType>STOP</messageType>
        <messageDetail>Test detail</messageDetail>
        <timestamp>2015-05-28T19:34:24.000Z</timestamp>
        <timeInGMTSecond>1432841664</timeInGMTSecond>
        <latitude>32.74293</latitude>
        <longitude>-97.14706</longitude>
        <batteryState>GOOD</batteryState>
      </message>
    XML
  end

  def parse_xml(xml)
    Nokogiri::XML(xml).at('message')
  end

  test "decodes valid XML message" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)

    assert messages.any?, "Should produce messages"
    sources = messages.map(&:source)

    assert_includes sources, 'location'
    assert_includes sources, 'battery'
  end

  test "extracts correct coordinates" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg
    lat, lng = location_msg.value.split(',').map(&:to_f)

    assert_in_delta 32.74293, lat, 0.00001
    assert_in_delta(-97.14706, lng, 0.00001)
  end

  test "extracts esn correctly" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_equal "0-2554023", location_msg.esn
  end

  test "extracts occurred_at from timeInGMTSecond" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_not_nil location_msg.occurred_at
    assert_equal 2015, location_msg.occurred_at.year
    assert_equal 5, location_msg.occurred_at.month
    assert_equal 28, location_msg.occurred_at.day
  end

  test "includes nickname in location meta" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert_equal "SPOT 1", meta['nickname']
  end

  test "includes message_type in location meta" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert_equal "STOP", meta['message_type']
  end

  test "includes more_detail in location meta" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert_equal "Test detail", meta['more_detail']
  end

  test "extracts good battery status" do
    doc = parse_xml(sample_xml)
    messages = @decoder.decode_message(doc)
    battery_msg = messages.find { |m| m.source == 'battery' }

    assert_not_nil battery_msg
    assert_equal 'g', battery_msg.value
  end

  test "extracts low battery status" do
    xml = sample_xml.gsub('GOOD', 'LOW')
    doc = parse_xml(xml)
    messages = @decoder.decode_message(doc)
    battery_msg = messages.find { |m| m.source == 'battery' }

    assert_equal 'b', battery_msg.value
  end

  test "handles missing battery state" do
    xml = sample_xml.gsub(/<batteryState>.*<\/batteryState>/, '')
    doc = parse_xml(xml)
    messages = @decoder.decode_message(doc)
    battery_msg = messages.find { |m| m.source == 'battery' }

    assert_nil battery_msg
  end

  test "handles missing coordinates" do
    xml = sample_xml.gsub(/<latitude>.*<\/latitude>/, '')
                    .gsub(/<longitude>.*<\/longitude>/, '')
    doc = parse_xml(xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    assert_nil location_msg
  end

  test "deduplicates identical messages" do
    doc = parse_xml(sample_xml)

    messages1 = @decoder.decode_message(doc)
    messages1.each(&:save!)

    messages2 = @decoder.decode_message(doc)
    location1 = messages1.find { |m| m.source == 'location' }
    location2 = messages2.find { |m| m.source == 'location' }

    assert location2.persisted?
    assert_equal location1.id, location2.id
  end

  test "handles TRACK message type" do
    xml = sample_xml.gsub('STOP', 'TRACK')
    doc = parse_xml(xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    assert_equal "TRACK", meta['message_type']
  end

  test "handles empty message detail" do
    xml = sample_xml.gsub('Test detail', '')
    doc = parse_xml(xml)
    messages = @decoder.decode_message(doc)
    location_msg = messages.find { |m| m.source == 'location' }

    meta = JSON.parse(location_msg.meta)
    # Empty string is not included in meta
    refute meta.key?('more_detail') unless meta['more_detail'].present?
  end
end
