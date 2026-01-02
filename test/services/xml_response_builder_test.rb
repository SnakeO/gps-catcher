require 'test_helper'

class XmlResponseBuilderTest < ActiveSupport::TestCase
  # STU Response Tests

  test "builds valid STU PASS response" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'STU Message OK',
      message_id: 123
    )

    assert_match(/PASS/, response)
    assert_match(/STU Message OK/, response)
    assert_match(/stuResponseMsg/, response)
  end

  test "builds valid STU FAIL response" do
    response = XmlResponseBuilder.stu_response(
      state: 'FAIL',
      message: 'malformed xml',
      message_id: 456
    )

    assert_match(/FAIL/, response)
    assert_match(/malformed xml/, response)
  end

  test "STU response includes message_id" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 789
    )

    assert_match(/messageID="789"/, response)
    assert_match(/correlationID="789"/, response)
  end

  test "STU response includes delivery timestamp" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    assert_match(/deliveryTimeStamp=/, response)
    # Should match format: DD/MM/YYYY HH:MM:SS ZONE
    assert_match(/\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}/, response)
  end

  test "STU response uses correct schema" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    assert_match(/StuResponse_Rev1_0\.xsd/, response)
  end

  test "STU response is valid XML" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    # Should not raise
    doc = Nokogiri::XML(response) { |config| config.strict }
    assert doc.errors.empty?
  end

  test "STU response has no newlines or tabs" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    refute_match(/\n/, response)
    refute_match(/\r/, response)
    refute_match(/\t/, response)
  end

  # PRV Response Tests

  test "builds valid PRV PASS response" do
    response = XmlResponseBuilder.prv_response(
      state: 'PASS',
      message: 'PRV Message OK',
      message_id: 123
    )

    assert_match(/PASS/, response)
    assert_match(/PRV Message OK/, response)
    assert_match(/prvResponseMsg/, response)
  end

  test "builds valid PRV FAIL response" do
    response = XmlResponseBuilder.prv_response(
      state: 'FAIL',
      message: 'error occurred',
      message_id: 456
    )

    assert_match(/FAIL/, response)
    assert_match(/error occurred/, response)
  end

  test "PRV response uses correct schema" do
    response = XmlResponseBuilder.prv_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    assert_match(/ProvisionResponse_Rev1_0\.xsd/, response)
  end

  test "PRV response is valid XML" do
    response = XmlResponseBuilder.prv_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    doc = Nokogiri::XML(response) { |config| config.strict }
    assert doc.errors.empty?
  end

  test "PRV response has no newlines or tabs" do
    response = XmlResponseBuilder.prv_response(
      state: 'PASS',
      message: 'OK',
      message_id: 1
    )

    refute_match(/\n/, response)
    refute_match(/\r/, response)
    refute_match(/\t/, response)
  end

  # Instance method tests

  test "instance can build STU response" do
    builder = XmlResponseBuilder.new(:stu)
    response = builder.build(state: 'PASS', message: 'OK', message_id: 1)

    assert_match(/stuResponseMsg/, response)
    assert_match(/PASS/, response)
  end

  test "instance can build PRV response" do
    builder = XmlResponseBuilder.new(:prv)
    response = builder.build(state: 'PASS', message: 'OK', message_id: 1)

    assert_match(/prvResponseMsg/, response)
    assert_match(/PASS/, response)
  end

  test "handles special characters in message" do
    response = XmlResponseBuilder.stu_response(
      state: 'FAIL',
      message: 'Error: <xml> & "quotes"',
      message_id: 1
    )

    # Should still be parseable
    doc = Nokogiri::XML(response)
    # The message contains special chars but should be in the response
    assert response.include?('Error:')
  end

  test "handles numeric message_id" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 12345
    )

    assert_match(/messageID="12345"/, response)
  end

  test "handles string message_id" do
    response = XmlResponseBuilder.stu_response(
      state: 'PASS',
      message: 'OK',
      message_id: 'abc-123'
    )

    assert_match(/messageID="abc-123"/, response)
  end
end
