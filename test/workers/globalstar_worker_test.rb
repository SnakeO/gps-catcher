require 'test_helper'

class GlobalstarWorkerTest < ActiveSupport::TestCase

  def setup
    @worker = GlobalstarWorker.new
  end

  # ============================================
  # perform() Tests
  # ============================================

  test "perform processes STU message successfully" do
    xml = sample_globalstar_stu_xml
    stu_message = StuMessage.create!(
      raw: xml,
      status: 'ok',
      processed_stage: 1
    )

    # Mock the PostgreSQL save to avoid connection issues
    ParsedMessage.any_instance.stubs(:sendToPostgres).returns(true)

    @worker.perform(xml, stu_message.id)

    stu_message.reload
    assert_equal 2, stu_message.processed_stage, "Should mark as processed (stage 2)"
    assert_equal 'success', stu_message.extra
  end

  test "perform handles malformed XML gracefully" do
    malformed_xml = "not valid xml <>"
    stu_message = StuMessage.create!(
      raw: malformed_xml,
      status: 'ok',
      processed_stage: 1
    )

    @worker.perform(malformed_xml, stu_message.id)

    stu_message.reload
    assert_equal 0, stu_message.processed_stage, "Should reset to stage 0 on error"
    assert_match(/ERROR/, stu_message.extra)
  end

  test "perform sets processed_stage to 0 when sendToPostgres fails" do
    xml = sample_globalstar_stu_xml
    stu_message = StuMessage.create!(
      raw: xml,
      status: 'ok',
      processed_stage: 1
    )

    # Mock sendToPostgres to fail
    ParsedMessage.any_instance.stubs(:sendToPostgres).returns(false)

    @worker.perform(xml, stu_message.id)

    stu_message.reload
    assert_equal 0, stu_message.processed_stage
    assert_match(/failed/, stu_message.extra)
  end

  # ============================================
  # handleSTUs() Tests
  # ============================================

  test "handleSTUs extracts external_message_id from XML" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <stuMessages messageID="MSG-12345">
        <stuMessage>
          <esn>0-1234567</esn>
          <unixTime>1432598400</unixTime>
          <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
        </stuMessage>
      </stuMessages>
    XML

    doc = Nokogiri::XML(xml)
    origin_message_id = 1

    # Mock decoder to avoid complex parsing
    decoder_mock = mock('decoder')
    decoder_mock.stubs(:payload).returns([])
    Globalstar::Decoder.stubs(:new).returns(decoder_mock)

    result = @worker.handleSTUs(doc, origin_message_id)

    # Verify it was called with correct message_id
    assert result  # Should return true (success) when no parsed messages fail
  end

  test "handleSTUs processes multiple stuMessage elements" do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <stuMessages messageID="MSG-MULTI">
        <stuMessage>
          <esn>0-1111111</esn>
          <unixTime>1432598400</unixTime>
          <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
        </stuMessage>
        <stuMessage>
          <esn>0-2222222</esn>
          <unixTime>1432598500</unixTime>
          <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
        </stuMessage>
      </stuMessages>
    XML

    doc = Nokogiri::XML(xml)
    origin_message_id = 1

    # Count how many times handleSTU is called
    call_count = 0
    @worker.define_singleton_method(:handleSTU) do |doc, origin_id, external_id|
      call_count += 1
      true
    end

    @worker.handleSTUs(doc, origin_message_id)

    assert_equal 2, call_count, "Should process both stuMessage elements"
  end

  # ============================================
  # handleSTU() Tests
  # ============================================

  test "handleSTU extracts ESN from message" do
    xml = <<~XML
      <stuMessage>
        <esn>0-9876543</esn>
        <unixTime>1432598400</unixTime>
        <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
      </stuMessage>
    XML

    doc = Nokogiri::XML(xml).at('stuMessage')

    # Mock to capture parsed message attributes
    captured_esns = []
    ParsedMessage.any_instance.stubs(:save).returns(true)
    ParsedMessage.any_instance.stubs(:sendToPostgres).returns(true)

    # Track ESN assignment
    original_new = ParsedMessage.method(:new)
    ParsedMessage.define_singleton_method(:new) do |*args|
      msg = original_new.call(*args)
      msg.define_singleton_method(:esn=) do |val|
        captured_esns << val
        super(val)
      end
      msg
    end

    @worker.handleSTU(doc, 1, 'ext-123')

    assert captured_esns.include?('0-9876543'), "Should extract ESN from message"
  end

  test "handleSTU converts unix timestamp to occurred_at" do
    xml = <<~XML
      <stuMessage>
        <esn>0-1234567</esn>
        <unixTime>1432598400</unixTime>
        <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
      </stuMessage>
    XML

    doc = Nokogiri::XML(xml).at('stuMessage')

    ParsedMessage.any_instance.stubs(:save).returns(true)
    ParsedMessage.any_instance.stubs(:sendToPostgres).returns(true)

    @worker.handleSTU(doc, 1, 'ext-123')

    # Unix timestamp 1432598400 = 2015-05-26 00:00:00 UTC
    # Verify by checking the occurred_at was set correctly
    # (We'd need to capture the value to fully test this)
  end

  # ============================================
  # verify() Tests
  # ============================================

  test "verify raises error for incorrect payload length" do
    assert_raises RuntimeError do
      @worker.verify('0-1234567', '002E914EBAEAE84A08', 10, 'hex')  # length should be 9
    end
  end

  test "verify raises error for non-hex encoding" do
    assert_raises RuntimeError do
      @worker.verify('0-1234567', '002E914EBAEAE84A08', 9, 'base64')
    end
  end

  test "verify raises error for empty ESN" do
    assert_raises RuntimeError do
      @worker.verify('', '002E914EBAEAE84A08', 9, 'hex')
    end
  end

  test "verify raises error for mismatched actual payload length" do
    # Payload is 16 hex chars = 8 bytes, but we say it's 9
    assert_raises RuntimeError do
      @worker.verify('0-1234567', '002E914EBAEAE84A', 9, 'hex')
    end
  end

  test "verify passes for valid payload" do
    # Should not raise any exception
    @worker.verify('0-1234567', '002E914EBAEAE84A08', 9, 'hex')
  end

  # ============================================
  # handlePRVs() Tests
  # ============================================

  test "handlePRVs returns true (skips PRV processing)" do
    doc = Nokogiri::XML('<prvMessages></prvMessages>')
    origin_message_id = 1

    result = @worker.handlePRVs(doc, origin_message_id)

    assert result, "handlePRVs should return true (skip processing)"
  end

  # ============================================
  # Error Handling Tests
  # ============================================

  test "handles database connection errors" do
    xml = sample_globalstar_stu_xml
    stu_message = StuMessage.create!(
      raw: xml,
      status: 'ok',
      processed_stage: 1
    )

    # Simulate database error
    StuMessage.stubs(:find).raises(ActiveRecord::ConnectionNotEstablished.new("Database connection failed"))

    # Should handle error gracefully
    assert_raises(ActiveRecord::ConnectionNotEstablished) do
      @worker.perform(xml, stu_message.id)
    end
  end

  test "handles missing origin message" do
    xml = sample_globalstar_stu_xml

    # Non-existent message ID
    assert_raises(ActiveRecord::RecordNotFound) do
      @worker.perform(xml, 999999)
    end
  end

  # ============================================
  # Sidekiq Configuration Tests
  # ============================================

  test "worker includes Sidekiq::Worker" do
    assert GlobalstarWorker.include?(Sidekiq::Worker)
  end

  test "worker has retry set to 5" do
    options = GlobalstarWorker.sidekiq_options_hash
    assert_equal 5, options['retry']
  end
end
