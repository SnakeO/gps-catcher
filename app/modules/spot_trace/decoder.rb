# frozen_string_literal: true

require 'json'

module SpotTrace
	class Decoder

		# decode decoded xml data into messages
		def message(doc)

			# EXAMPLES (except it's already parsed into a doc)
			# ==================================
			# 	 <message>
			# 		  <id>399196236</id>
			# 		  <esn>0-2554023</esn>
			# 		  <esnName>SPOT 1</esnName>
			# 		  <messageType>STOP</messageType>
			# 		  <messageDetail></messageDetail>
			# 		  <timestamp>2015-05-28T19:34:24.000Z</timestamp>
			# 		  <timeInGMTSecond>1432841664</timeInGMTSecond>
			# 		  <latitude>32.74293</latitude>
			# 		  <longitude>-97.14706</longitude>
			# 		  <batteryState>GOOD</batteryState>
			# 	 </message>


			# break it into messages
			messages = []

			@external_message_id = doc.css('id').text()
			@esn = doc.css('esn').text()
			esnName = doc.css('esnName').text()
			messageType = doc.css('messageType').text()
			messageDetail = doc.css('messageDetail').text()
			timestamp = doc.css('timestamp').text()
			timeInGMTSecond = doc.css('timeInGMTSecond').text()
			@occurred_at = Time.at(timeInGMTSecond.to_i).utc()
			
			latitude = doc.css('latitude').text()
			longitude = doc.css('longitude').text()

			# location
			loc_msg = getLocationMsg(latitude, longitude, {
				nickname: esnName,
				more_detail: messageDetail,
				message_type: messageType
			})
			messages << loc_msg if loc_msg

			# battery
			batt_value = doc.css('batteryState').text()
			batt_msg = getBatteryMsg(batt_value)
			messages << batt_msg if batt_msg

			messages
		end

		def getLocationMsg(latitude, longitude, meta)
			source = 'location'
			value = "#{latitude},#{longitude}"
			
			# already exists?
			loc_msg = ParsedMessage.findExisting(@external_message_id, source, value, JSON.generate(meta))
			return loc_msg if loc_msg != nil

			loc_message = ParsedMessage.new
			loc_message.source = source
			loc_message.value = value
			loc_message.meta = JSON.generate(meta)
			loc_message.message_id = loc_message.makeHashID(@external_message_id)

			loc_message.occurred_at = @occurred_at
			loc_message.esn = @esn

			loc_message
		end

		def getBatteryMsg(battery_value)

			source = 'battery'
			value = battery_value.downcase == 'good' ? 'g' : 'b'	# GOOD or LOW

			# already exists?
			batt_msg = ParsedMessage.findExisting(@external_message_id, source, value)
			return batt_msg if batt_msg != nil

			batt_msg = ParsedMessage.new
			batt_msg.source = source
			batt_msg.value = value
			batt_msg.message_id = batt_msg.makeHashID(@external_message_id)

			batt_msg.occurred_at = @occurred_at	# we're using the occurred_at of the last location msg since there's no separate time for this mag
			batt_msg.esn = @esn

			batt_msg
		end

	end
end