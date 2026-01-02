# Decoder for GPS306A tracker messages
# Handles comma-separated location messages with NMEA-format coordinates
class Gps306aDecoder < BaseDecoder
  # Decode a GPS306A location message from CSV fields
  # Format: imei:IMEI,tracker,YYMMDDHHMMSS,,F,HHMMSS.SSS,A,LAT,N/S,LNG,E/W,...
  # Returns array of ParsedMessage objects
  def decode_location_message(fields)
    parse_header_fields(fields)
    parse_coordinates(fields)
    build_messages(fields)
  end

  private

  def parse_header_fields(fields)
    # Extract IMEI (removes 'imei:' prefix)
    imei_field = fields.shift
    set_esn(imei_field.sub('imei:', ''))

    # Device name (usually 'tracker')
    @device_name = fields.shift

    # Parse date/time - format YYMMDDHHMMSS, prefix with '20' for century
    date_str = fields.shift
    set_occurred_at(parse_gps306a_time(date_str))

    # Skip empty field and 'F' marker
    fields.shift  # empty
    fields.shift  # 'F'

    # External message ID is the time field (HHMMSS.SSS)
    set_external_message_id(fields.shift)

    # Skip 'A' marker (valid fix)
    fields.shift
  end

  def parse_coordinates(fields)
    # Latitude in NMEA format: DDMM.MMMM
    lat_nmea = fields.shift
    n_or_s = fields.shift

    # Longitude in NMEA format: DDDMM.MMMM
    lng_nmea = fields.shift
    e_or_w = fields.shift

    @latitude = nmea_to_decimal(lat_nmea, n_or_s, :latitude)
    @longitude = nmea_to_decimal(lng_nmea, e_or_w, :longitude)
  end

  def build_messages(fields)
    messages = []

    # Skip to azimuth
    fields.shift  # unknown/speed
    azimuth = fields.shift

    # Location message
    loc_msg = build_location_message(
      latitude: @latitude,
      longitude: @longitude,
      meta: { azimuth: azimuth }.compact
    )
    messages << loc_msg if loc_msg

    messages.compact
  end

  # Convert NMEA format (DDMM.MMMM or DDDMM.MMMM) to decimal degrees
  def nmea_to_decimal(nmea_value, hemisphere, coord_type)
    return nil if nmea_value.nil? || nmea_value.empty?

    # Latitude: first 2 chars are degrees, rest is minutes
    # Longitude: first 3 chars are degrees, rest is minutes
    if coord_type == :latitude
      degrees = nmea_value[0..1].to_i
      minutes = nmea_value[2..-1].to_f
    else
      degrees = nmea_value[0..2].to_i
      minutes = nmea_value[3..-1].to_f
    end

    decimal = degrees + (minutes / 60.0)

    # Apply hemisphere sign
    if hemisphere == 'S' || hemisphere == 'W'
      -decimal
    else
      decimal
    end
  end

  # Parse GPS306A timestamp format: YYMMDDHHMMSS
  def parse_gps306a_time(time_str)
    return Time.now.utc if time_str.nil? || time_str.empty?
    # Add century prefix and parse as UTC
    Time.parse("20#{time_str}Z").utc
  rescue ArgumentError
    Time.now.utc
  end
end
