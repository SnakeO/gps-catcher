# Factory for creating ParsedMessage instances
# Handles deduplication and consistent message creation across all decoders
class ParsedMessageFactory
  class << self
    # Create a location message
    def location(external_message_id:, coordinates:, meta: {})
      source = 'location'
      value = coordinates.to_s
      meta_json = meta.to_json

      find_or_build(
        external_message_id: external_message_id,
        source: source,
        value: value,
        meta: meta_json
      )
    end

    # Create a battery message
    def battery(external_message_id:, good:)
      source = 'battery'
      value = good ? 'g' : 'b'

      find_or_build(
        external_message_id: external_message_id,
        source: source,
        value: value
      )
    end

    # Create a power/turned on message
    def power(external_message_id:, state:)
      source = 'powered'
      value = state.to_s

      find_or_build(
        external_message_id: external_message_id,
        source: source,
        value: value
      )
    end

    # Create an in-motion message
    def motion(external_message_id:, in_motion:)
      source = 'is_in_motion'
      value = in_motion.to_s

      find_or_build(
        external_message_id: external_message_id,
        source: source,
        value: value
      )
    end

    # Create a generic info message
    def info(external_message_id:, source:, value:, meta: nil)
      meta_json = meta&.to_json

      find_or_build(
        external_message_id: external_message_id,
        source: source,
        value: value.to_s,
        meta: meta_json
      )
    end

    private

    def find_or_build(external_message_id:, source:, value:, meta: nil)
      existing = ParsedMessage.findExisting(external_message_id, source, value, meta)
      return existing if existing

      message = ParsedMessage.new
      message.source = source
      message.value = value
      message.meta = meta
      message.message_id = message.makeHashID(external_message_id)
      message
    end
  end
end
