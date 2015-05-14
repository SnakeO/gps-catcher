# == Schema Information
#
# Table name: parsed_messages
#
#  id                  :integer          not null, primary key
#  origin_message_type :string(255)
#  origin_message_id   :integer
#  esn                 :string(255)
#  source              :string(255)
#  value               :string(255)
#  meta                :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class ParsedMessage < ActiveRecord::Base

	def makeHashID (external_message_id)
		ParsedMessage.makeHashID(external_message_id, self.source, self.value, self.meta)
	end

	# return a unique_id for this parsed_message based on some of it's values
	def self.makeHashID(external_message_id, source, value, meta)
		hashme = "#{source}#{value}#{meta}"
		hashed = Digest::MD5.hexdigest(hashme)
		"#{external_message_id}-#{hashed}"
	end

	def self.findExisting(external_message_id, source, value, meta=nil)
		hash_id = ParsedMessage.makeHashID(external_message_id, source, value, meta)
		return ParsedMessage.find_by_message_id hash_id
	end
end