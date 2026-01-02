# Base class for all GPS device decoders
# Provides common message building methods using ParsedMessageFactory
# Subclasses implement device-specific parsing logic
class BaseDecoder
  class DecodingError < StandardError; end

  protected

  attr_reader :external_message_id, :esn, :occurred_at

  # Set the external message ID for deduplication
  def set_external_message_id(id)
    @external_message_id = id
  end

  # Set the device ESN/IMEI
  def set_esn(esn)
    @esn = esn
  end

  # Set when the message occurred
  def set_occurred_at(time)
    @occurred_at = time.is_a?(Time) ? time.utc : Time.parse(time.to_s).utc
  end

  # Build a location message using the Coordinates value object
  # Returns nil if coordinates are invalid
  def build_location_message(latitude:, longitude:, meta: {})
    coordinates = create_coordinates(latitude, longitude)
    return nil unless coordinates

    message = ParsedMessageFactory.location(
      external_message_id: external_message_id,
      coordinates: coordinates,
      meta: meta
    )
    apply_common_attributes(message)
    message
  rescue Coordinates::InvalidCoordinatesError
    nil
  end

  # Build a battery message
  # good: true/false or string 'GOOD'/'LOW'/'g'/'b' or percentage 0-100
  def build_battery_message(good:)
    good_value = normalize_battery_value(good)

    message = ParsedMessageFactory.battery(
      external_message_id: external_message_id,
      good: good_value
    )
    apply_common_attributes(message)
    message
  end

  # Build a battery message with percentage value
  def build_battery_percentage_message(percentage:)
    message = ParsedMessageFactory.info(
      external_message_id: external_message_id,
      source: 'battery',
      value: percentage.to_s
    )
    apply_common_attributes(message)
    message
  end

  # Build a power/turned on message
  def build_power_message(state:)
    message = ParsedMessageFactory.power(
      external_message_id: external_message_id,
      state: state
    )
    apply_common_attributes(message)
    message
  end

  # Build an in-motion message
  def build_motion_message(in_motion:)
    motion_value = in_motion.is_a?(Integer) ? in_motion : (in_motion ? 1 : 0)

    message = ParsedMessageFactory.motion(
      external_message_id: external_message_id,
      in_motion: motion_value
    )
    apply_common_attributes(message)
    message
  end

  # Build a generic info message
  def build_info_message(source:, value:, meta: nil)
    message = ParsedMessageFactory.info(
      external_message_id: external_message_id,
      source: source,
      value: value,
      meta: meta
    )
    apply_common_attributes(message)
    message
  end

  private

  # Create a Coordinates value object from lat/lng
  # Returns nil if coordinates are invalid
  def create_coordinates(latitude, longitude)
    Coordinates.new(latitude, longitude)
  rescue Coordinates::InvalidCoordinatesError
    nil
  end

  # Normalize battery value to boolean
  def normalize_battery_value(value)
    case value
    when true, false
      value
    when 'GOOD', 'good', 'g', 'G'
      true
    when 'LOW', 'low', 'b', 'B', 'BAD', 'bad'
      false
    when Integer, Float
      value >= 50 # Consider 50%+ as "good"
    else
      value.to_s.downcase == 'good'
    end
  end

  # Apply common attributes to a message
  def apply_common_attributes(message)
    return if message.nil? || message.persisted?

    message.esn = esn if message.respond_to?(:esn=)
    message.occurred_at = occurred_at if message.respond_to?(:occurred_at=)
  end
end
