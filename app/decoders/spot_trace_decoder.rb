# Decoder for SPOT Trace satellite GPS tracker messages
# Handles XML document parsing from SPOT API
class SpotTraceDecoder < BaseDecoder
  # Known message types from SPOT devices
  MESSAGE_TYPES = %w[
    TRACK
    STOP
    CUSTOM
    OK
    HELP
    EXTREME
    NEWMOVEMENT
    UNLIMITED-TRACK
  ].freeze

  # Decode a SPOT Trace XML message document
  # doc: Nokogiri XML document node
  # Returns array of ParsedMessage objects
  def decode_message(doc)
    parse_message_fields(doc)
    build_messages(doc)
  end

  private

  def parse_message_fields(doc)
    set_external_message_id(extract_text(doc, 'id'))
    set_esn(extract_text(doc, 'esn'))

    # Parse timestamp from Unix seconds
    time_in_gmt = extract_text(doc, 'timeInGMTSecond')
    if time_in_gmt.present?
      set_occurred_at(Time.at(time_in_gmt.to_i).utc)
    else
      # Fall back to ISO timestamp
      timestamp = extract_text(doc, 'timestamp')
      set_occurred_at(Time.parse(timestamp).utc) if timestamp.present?
    end
  end

  def build_messages(doc)
    messages = []

    # Location message
    latitude = extract_text(doc, 'latitude')
    longitude = extract_text(doc, 'longitude')

    if latitude.present? && longitude.present?
      loc_msg = build_location_message(
        latitude: latitude.to_f,
        longitude: longitude.to_f,
        meta: build_location_meta(doc)
      )
      messages << loc_msg if loc_msg
    end

    # Battery message
    battery_state = extract_text(doc, 'batteryState')
    if battery_state.present?
      messages << build_battery_message(good: battery_state)
    end

    messages.compact
  end

  def build_location_meta(doc)
    {
      nickname: extract_text(doc, 'esnName'),
      message_type: extract_text(doc, 'messageType'),
      more_detail: extract_text(doc, 'messageDetail')
    }.compact
  end

  def extract_text(doc, selector)
    text = doc.css(selector).text
    text.present? ? text : nil
  end
end
