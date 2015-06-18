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

	# save to postgres
	# http://exposinggotchas.blogspot.com/2011/02/activerecord-migrations-without-rails.html
	def sendToPostgres

		# skip messages that have already been sent
		return true if self.is_sent

		self.num_tries += 1
		msg = nil

		begin
			
			if self.source == 'location'

				latlng = self.value.split(',')
				lat = latlng[0]
				lng = latlng[1]

				# smartoneb does this
				if lat == '0.0' && lng == '0.0'
					raise "Lat and Lng are both 0.0"
				end

				# spot trace does this
				if lat == '-99999.0' && lng == '-99999.0'
					raise "Lat and Lng are both -99999.0"
				end

				msg = LocationMsg.new(
					esn: self.esn, 
					occurred_at: self.occurred_at,
					point: RGeo::Geographic.spherical_factory(:srid => 4326).point(lng, lat),
					meta: self.meta,
					message_id: self.message_id
				)

				msg.save
				
			else

				msg = InfoMsg.new(
					esn: self.esn, 
					occurred_at: self.occurred_at,
					source: self.source,
					value: self.value,
					meta: self.meta,
					message_id: self.message_id
				)

				msg.save
			
			end

			self.is_sent = true
			self.save

		rescue Exception => e
				
			# log the error
			self.is_sent = false
			self.info = "PG INSERT ERROR: #{e}"
			puts self.info
			self.save

			return false

		end

		true
	end
end