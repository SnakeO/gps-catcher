# Decoder for Globalstar satellite GPS tracker messages
# Handles binary payload decoding with two's complement lat/lng
class GlobalstarDecoder < BaseDecoder
  # Message type constants
  MESSAGE_TYPES = {
    0 => :location,           # Regular scheduled location report
    1 => :power_on,           # Device was turned on
    2 => :change_of_location, # Left Change of Location area
    3 => :input_change,       # Input state changed
    4 => :undesired_input,    # Undesired input state report
    5 => :recenter            # Reduced Messaging Mode re-center
  }.freeze

  # Decode a Globalstar binary payload
  # Returns array of ParsedMessage objects
  def decode_payload(payload, external_message_id)
    set_external_message_id(external_message_id)

    # Payload is hex string, e.g., "002E914EBAEAE84A08"
    # 72 bits total (9 bytes = 18 hex chars)
    data = parse_binary_payload(payload)

    build_messages(data)
  end

  private

  # Parse the binary payload into a structured hash
  def parse_binary_payload(payload)
    num_bits = payload.length * 4
    bin = payload.to_i(16).to_s(2).rjust(num_bits, '0')

    # 72-bit payload structure:
    # Bits 0-1:   Type (2 bits)
    # Bit 2:      Battery Good (1 bit, 0 = good)
    # Bit 3:      GPS Data Valid (1 bit, 0 = valid)
    # Bits 4-5:   Missed Input (2 bits)
    # Bits 6-7:   GPS Fail Counter (2 bits)
    # Bits 8-31:  Latitude (24 bits, two's complement)
    # Bits 32-55: Longitude (24 bits, two's complement)
    # Bits 56-59: Input Status (4 bits)
    # Bits 60-63: Message Sub-Type (4 bits)
    # Bits 64-66: Unused (3 bits)
    # Bit 67:     Vibration Triggered (1 bit)
    # Bit 68:     Vibration Bit (1 bit)
    # Bit 69:     2D Fix (1 bit)
    # Bit 70:     In Motion (1 bit)
    # Bit 71:     Fix Confidence (1 bit, 0 = high)

    {
      type: bin[0, 2].to_i(2),
      good_battery: bin[2, 1].to_i(2),
      gps_valid: bin[3, 1].to_i(2),
      missed_input: bin[4, 2].to_i(2),
      gps_fail_counter: bin[6, 2].to_i(2),
      lat_bin: bin[8, 24],
      lng_bin: bin[32, 24],
      input_status: bin[56, 4].to_i(2),
      message_sub_type: bin[60, 4].to_i(2),
      vibration_triggered: bin[67, 1].to_i(2),
      vibration_bit: bin[68, 1].to_i(2),
      two_d_fix: bin[69, 1].to_i(2),
      in_motion: bin[70, 1].to_i(2),
      fix_confidence: bin[71, 1].to_i(2)
    }
  end

  # Build all messages from parsed data
  def build_messages(data)
    messages = []

    # Battery message (always included)
    messages << build_battery_message(good: data[:good_battery] == 0)

    # Location message (only if GPS data valid)
    if data[:gps_valid] == 0
      latitude = lat_from_binary(data[:lat_bin])
      longitude = lng_from_binary(data[:lng_bin])

      loc_msg = build_location_message(
        latitude: latitude,
        longitude: longitude,
        meta: {
          twoD: data[:two_d_fix],
          is_in_motion: data[:in_motion],
          confidence: data[:fix_confidence] == 0 ? 1 : 0
        }
      )
      messages << loc_msg if loc_msg
    end

    # Sub-type specific message (power on, etc.)
    sub_type_msg = build_sub_type_message(data[:message_sub_type])
    messages << sub_type_msg if sub_type_msg

    # In-motion message
    messages << build_motion_message(in_motion: data[:in_motion])

    messages.compact
  end

  # Convert two's complement binary string to latitude
  def lat_from_binary(bin)
    value = twos_complement_to_int(bin)
    value * (90.0 / (2**23))
  end

  # Convert two's complement binary string to longitude
  def lng_from_binary(bin)
    value = twos_complement_to_int(bin)
    value * (180.0 / (2**23))
  end

  # Convert two's complement binary string to signed integer
  def twos_complement_to_int(bin)
    if bin[0] == '1'
      # Negative: invert bits and add 1
      inverted = bin.chars.map { |b| b == '0' ? '1' : '0' }.join
      -(inverted.to_i(2) + 1)
    else
      bin.to_i(2)
    end
  end

  # Build message based on sub-type
  def build_sub_type_message(sub_type)
    case MESSAGE_TYPES[sub_type]
    when :power_on
      build_power_message(state: 'on')
    when :change_of_location
      build_info_message(source: 'alert', value: 'change_of_location')
    when :input_change
      build_info_message(source: 'alert', value: 'input_change')
    when :undesired_input
      build_info_message(source: 'alert', value: 'undesired_input')
    when :recenter
      build_info_message(source: 'alert', value: 'recenter')
    else
      nil
    end
  end
end
