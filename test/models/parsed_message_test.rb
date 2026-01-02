require 'test_helper'

class ParsedMessageTest < ActiveSupport::TestCase

  # ============================================
  # makeHashID Tests
  # ============================================

  test "makeHashID class method generates consistent hash" do
    hash1 = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', '{"speed":10}')
    hash2 = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', '{"speed":10}')

    assert_equal hash1, hash2, "Same inputs should produce same hash"
  end

  test "makeHashID class method includes external_message_id prefix" do
    hash = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', nil)

    assert hash.start_with?('ext123-'), "Hash should be prefixed with external_message_id"
  end

  test "makeHashID class method produces different hashes for different sources" do
    hash1 = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', nil)
    hash2 = ParsedMessage.makeHashID('ext123', 'battery', '32.7,-97.1', nil)

    refute_equal hash1, hash2, "Different sources should produce different hashes"
  end

  test "makeHashID class method produces different hashes for different values" do
    hash1 = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', nil)
    hash2 = ParsedMessage.makeHashID('ext123', 'location', '33.0,-98.0', nil)

    refute_equal hash1, hash2, "Different values should produce different hashes"
  end

  test "makeHashID instance method uses object attributes" do
    msg = ParsedMessage.new(source: 'location', value: '32.7,-97.1', meta: '{}')

    instance_hash = msg.makeHashID('ext123')
    class_hash = ParsedMessage.makeHashID('ext123', 'location', '32.7,-97.1', '{}')

    assert_equal instance_hash, class_hash
  end

  # ============================================
  # findExisting Tests
  # ============================================

  test "findExisting returns nil when no match exists" do
    result = ParsedMessage.findExisting('nonexistent', 'location', '0,0')

    assert_nil result
  end

  test "findExisting returns existing message when match exists" do
    # Create a message with a known message_id
    existing = ParsedMessage.create!(
      source: 'location',
      value: '32.7,-97.1',
      meta: nil,
      esn: 'test-esn',
      message_id: ParsedMessage.makeHashID('ext456', 'location', '32.7,-97.1', nil)
    )

    result = ParsedMessage.findExisting('ext456', 'location', '32.7,-97.1', nil)

    assert_not_nil result
    assert_equal existing.id, result.id
  end

  test "findExisting considers meta in matching" do
    # Create message with specific meta
    ParsedMessage.create!(
      source: 'location',
      value: '32.7,-97.1',
      meta: '{"speed":10}',
      esn: 'test-esn',
      message_id: ParsedMessage.makeHashID('ext789', 'location', '32.7,-97.1', '{"speed":10}')
    )

    # Should not find with different meta
    result_different_meta = ParsedMessage.findExisting('ext789', 'location', '32.7,-97.1', '{"speed":20}')
    assert_nil result_different_meta

    # Should find with same meta
    result_same_meta = ParsedMessage.findExisting('ext789', 'location', '32.7,-97.1', '{"speed":10}')
    assert_not_nil result_same_meta
  end

  # ============================================
  # sendToPostgres Tests (mocked - no actual PG connection in test)
  # ============================================

  test "sendToPostgres returns true if already sent" do
    msg = ParsedMessage.new(
      source: 'location',
      value: '32.7,-97.1',
      esn: 'test-esn',
      is_sent: true,
      num_tries: 0
    )

    result = msg.sendToPostgres

    assert result, "Should return true when already sent"
    assert_equal 0, msg.num_tries, "Should not increment num_tries when already sent"
  end

  test "sendToPostgres increments num_tries on each attempt" do
    msg = ParsedMessage.new(
      source: 'location',
      value: '32.7,-97.1',
      esn: 'test-esn',
      is_sent: false,
      num_tries: 0,
      occurred_at: Time.now,
      message_id: 'test-msg-id'
    )

    # Mock LocationMsg to avoid actual database calls
    LocationMsg.stubs(:new).raises(StandardError.new("Mocked error"))

    msg.sendToPostgres

    assert_equal 1, msg.num_tries
  end

  test "sendToPostgres rejects zero coordinates" do
    msg = ParsedMessage.new(
      source: 'location',
      value: '0.0,0.0',
      esn: 'test-esn',
      is_sent: false,
      num_tries: 0,
      occurred_at: Time.now,
      message_id: 'test-msg-id'
    )

    result = msg.sendToPostgres

    assert_equal false, result
    assert_match(/0\.0/, msg.info)
  end

  test "sendToPostgres rejects invalid spot trace coordinates" do
    msg = ParsedMessage.new(
      source: 'location',
      value: '-99999.0,-99999.0',
      esn: 'test-esn',
      is_sent: false,
      num_tries: 0,
      occurred_at: Time.now,
      message_id: 'test-msg-id'
    )

    result = msg.sendToPostgres

    assert_equal false, result
    assert_match(/-99999/, msg.info)
  end

  test "sendToPostgres handles non-location source as InfoMsg" do
    msg = ParsedMessage.new(
      source: 'battery',
      value: 'good',
      esn: 'test-esn',
      is_sent: false,
      num_tries: 0,
      occurred_at: Time.now,
      message_id: 'test-msg-id'
    )

    # Mock InfoMsg
    mock_info_msg = mock('InfoMsg')
    mock_info_msg.stubs(:save).returns(true)
    InfoMsg.stubs(:new).returns(mock_info_msg)

    result = msg.sendToPostgres

    assert result, "Should return true for successful InfoMsg save"
    assert msg.is_sent, "Should mark as sent"
  end

  # ============================================
  # Validation / Edge Case Tests
  # ============================================

  test "parsed message can be created with required attributes" do
    msg = ParsedMessage.new(
      source: 'location',
      value: '32.7,-97.1',
      esn: 'device123'
    )

    assert msg.valid?
  end

  test "parsed message stores origin message info" do
    msg = ParsedMessage.create!(
      source: 'location',
      value: '32.7,-97.1',
      esn: 'device123',
      origin_message_type: 'stu',
      origin_message_id: 42
    )

    assert_equal 'stu', msg.origin_message_type
    assert_equal 42, msg.origin_message_id
  end
end
