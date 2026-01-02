# Service for building Globalstar XML responses
# Handles STU and PRV response formats
class XmlResponseBuilder
  SCHEMAS = {
    stu: 'http://cody.glpconnect.com/XSD/StuResponse_Rev1_0.xsd',
    prv: 'http://cody.glpconnect.com/XSD/ProvisionResponse_Rev1_0.xsd'
  }.freeze

  ROOT_ELEMENTS = {
    stu: 'stuResponseMsg',
    prv: 'prvResponseMsg'
  }.freeze

  # Build an STU response
  def self.stu_response(state:, message:, message_id:)
    new(:stu).build(state: state, message: message, message_id: message_id)
  end

  # Build a PRV response
  def self.prv_response(state:, message:, message_id:)
    new(:prv).build(state: state, message: message, message_id: message_id)
  end

  def initialize(response_type)
    @response_type = response_type
    @schema = SCHEMAS[response_type]
    @root_element = ROOT_ELEMENTS[response_type]
  end

  def build(state:, message:, message_id:)
    xml = build_xml_template
    xml = substitute_placeholders(xml, state, message, message_id)
    strip_whitespace(xml)
  end

  private

  def build_xml_template
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <#{@root_element} xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="#{@schema}" deliveryTimeStamp="{delivery_timestamp}" messageID="{message_id}" correlationID="{message_id}">
        <state>{state}</state>
        <stateMessage>{message}</stateMessage>
      </#{@root_element}>
    XML
  end

  def substitute_placeholders(xml, state, message, message_id)
    xml.gsub('{state}', state.to_s)
       .gsub('{message}', message.to_s)
       .gsub('{message_id}', message_id.to_s)
       .gsub('{delivery_timestamp}', format_timestamp)
  end

  def format_timestamp
    time = Time.now
    "#{time.strftime('%d/%m/%Y %H:%M:%S')} #{time.zone}"
  end

  def strip_whitespace(xml)
    xml.gsub(/\r/, '')
       .gsub(/\n/, '')
       .gsub(/\t/, '')
  end
end
