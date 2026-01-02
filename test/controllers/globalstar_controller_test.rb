require 'test_helper'

class GlobalstarControllerTest < ActionController::TestCase

  # ============================================
  # STU Endpoint Tests
  # ============================================

  test "stu accepts valid XML and returns PASS response" do
    valid_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <stuMessages messageID="test123">
        <stuMessage>
          <esn>0-1234567</esn>
          <unixTime>1432598400</unixTime>
          <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
        </stuMessage>
      </stuMessages>
    XML

    # Stub worker to avoid actual processing
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    assert_match /PASS/, response.body
    assert_match /STU Message OK/, response.body
  end

  test "stu creates StuMessage record for valid XML" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    assert_difference('StuMessage.count', 1) do
      post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }
    end

    message = StuMessage.last
    assert_equal 'ok', message.status
    assert_equal 1, message.processed_stage
  end

  test "stu enqueues GlobalstarWorker" do
    valid_xml = sample_globalstar_stu_xml

    GlobalstarWorker.expects(:perform_async).once

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }
  end

  test "stu returns FAIL response for malformed XML" do
    malformed_xml = "this is not valid xml <><>"

    post :stu, malformed_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success  # Still returns 200, but with FAIL state
    assert_match /FAIL/, response.body
    assert_match /malformed xml/, response.body
  end

  test "stu creates StuMessage with malformed status for bad XML" do
    malformed_xml = "invalid <xml"

    assert_difference('StuMessage.count', 1) do
      post :stu, malformed_xml, { 'CONTENT_TYPE' => 'application/xml' }
    end

    message = StuMessage.last
    assert_equal 'malformed', message.status
    assert_equal(-1, message.processed_stage)
  end

  test "stu response includes message_id" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_match /messageID=/, response.body
  end

  test "stu response includes delivery timestamp" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_match /deliveryTimeStamp=/, response.body
  end

  # ============================================
  # PRV Endpoint Tests
  # ============================================

  test "prv accepts valid XML and returns PASS response" do
    valid_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <prvMessages messageID="prv123">
        <prvMessage>
          <esn>0-1234567</esn>
          <action>provision</action>
        </prvMessage>
      </prvMessages>
    XML

    post :prv, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    assert_match /PASS/, response.body
    assert_match /PRV Message OK/, response.body
  end

  test "prv creates PrvMessage record for valid XML" do
    valid_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <prvMessages messageID="prv123">
        <prvMessage>
          <esn>0-1234567</esn>
        </prvMessage>
      </prvMessages>
    XML

    assert_difference('PrvMessage.count', 1) do
      post :prv, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }
    end

    message = PrvMessage.last
    assert_equal 'ok', message.status
  end

  test "prv returns FAIL response for malformed XML" do
    malformed_xml = "not valid <xml"

    post :prv, malformed_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    assert_match /FAIL/, response.body
    assert_match /malformed xml/, response.body
  end

  test "prv creates PrvMessage with malformed status for bad XML" do
    malformed_xml = "<<<invalid"

    assert_difference('PrvMessage.count', 1) do
      post :prv, malformed_xml, { 'CONTENT_TYPE' => 'application/xml' }
    end

    message = PrvMessage.last
    assert_equal 'malformed', message.status
  end

  test "prv does not enqueue worker (PRVs are not processed)" do
    valid_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <prvMessages><prvMessage></prvMessage></prvMessages>
    XML

    GlobalstarWorker.expects(:perform_async).never

    post :prv, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }
  end

  # ============================================
  # Response Format Tests
  # ============================================

  test "stu response is valid XML" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    # Should not raise
    doc = Nokogiri::XML(response.body) { |config| config.strict }
    assert doc.errors.empty?, "Response should be valid XML"
  end

  test "stu response has stuResponseMsg root element" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    doc = Nokogiri::XML(response.body)
    assert_not_nil doc.at('stuResponseMsg')
  end

  test "prv response has prvResponseMsg root element" do
    valid_xml = '<prvMessages><prvMessage></prvMessage></prvMessages>'

    post :prv, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    doc = Nokogiri::XML(response.body)
    assert_not_nil doc.at('prvResponseMsg')
  end

  test "response has no line breaks or tabs" do
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    refute_match /\n/, response.body
    refute_match /\t/, response.body
  end

  # ============================================
  # CSRF Protection Tests
  # ============================================

  test "stu endpoint skips CSRF verification" do
    # If CSRF was required, this would fail without a token
    valid_xml = sample_globalstar_stu_xml
    GlobalstarWorker.stubs(:perform_async)

    post :stu, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
  end

  test "prv endpoint skips CSRF verification" do
    valid_xml = '<prvMessages><prvMessage></prvMessage></prvMessages>'

    post :prv, valid_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
  end

  # ============================================
  # Edge Cases
  # ============================================

  test "stu handles empty body" do
    post :stu, '', { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    assert_match /FAIL/, response.body
  end

  test "prv handles empty body" do
    post :prv, '', { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    assert_match /FAIL/, response.body
  end

  test "stu handles very large payload" do
    large_xml = "<stuMessages>#{'<data>' * 1000}</stuMessages>"

    post :stu, large_xml, { 'CONTENT_TYPE' => 'application/xml' }

    assert_response :success
    # Should create a record even if XML structure is unusual
  end
end
