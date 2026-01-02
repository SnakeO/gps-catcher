# Decoder for Queclink GL200 GPS tracker messages
# Handles CSV-formatted position reports
class Gl200Decoder < BaseDecoder
  # Decode a GL200 position report from CSV fields
  # Returns array of ParsedMessage objects
  def decode_position_report(fields)
    messages = []

    # Parse header fields
    # Format: +RESP:GTFRI,protocol,esn,device_name,append_mask,report_type,num_points,...
    parse_header_fields(fields)

    # Parse location points (there can be multiple per message)
    @num_points.times do
      loc_msg = parse_location_point(fields)
      messages << loc_msg if loc_msg
    end

    # Parse battery (comes after all location points)
    battery_value = fields.shift.to_i
    messages << build_battery_percentage_message(percentage: battery_value) if battery_value > 0

    messages.compact
  end

  private

  def parse_header_fields(fields)
    # Pop the external message ID from the end
    set_external_message_id(fields.pop)

    @protocol_version = fields.shift
    set_esn(fields.shift)
    @device_name = fields.shift
    @append_mask = fields.shift.to_i
    @report_type = fields.shift.to_i  # 0 = scheduled, 1 = user triggered
    @num_points = fields.shift.to_i
  end

  def parse_location_point(fields)
    gps_accuracy = fields.shift.to_i
    speed = fields.shift.to_f
    azimuth = fields.shift.to_f
    altitude = fields.shift.to_f
    longitude = fields.shift.to_f
    latitude = fields.shift.to_f
    gps_time = fields.shift  # e.g., "20150526000208"

    set_occurred_at(parse_gl200_time(gps_time))

    # Skip unused cell tower fields
    4.times { fields.shift }

    # Odometer
    odo_mileage = fields.shift

    # Calculate confidence (lower gps_accuracy = higher confidence)
    # Max gps_accuracy value is 50, lower is better
    confidence = gps_accuracy <= 50 ? (50 - gps_accuracy) / 50.0 : 0.0

    build_location_message(
      latitude: latitude,
      longitude: longitude,
      meta: {
        confidence: confidence,
        speed: speed,
        altitude: altitude,
        gps_accuracy: gps_accuracy,
        odometer: odo_mileage
      }
    )
  end

  # Parse GL200 timestamp format: YYYYMMDDHHMMSS (UTC time)
  def parse_gl200_time(time_str)
    return Time.now.utc if time_str.nil? || time_str.empty?
    # Treat as UTC by appending 'Z' before parsing
    Time.parse("#{time_str}Z").utc
  rescue ArgumentError
    Time.now.utc
  end
end
