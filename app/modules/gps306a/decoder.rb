require 'json'

module Gps306a
	class Decoder

		# decode location message fields into messages
		def locationMessage(fields)

			# EXAMPLES
			# ==================================
			# imei:359710049084651,tracker,150828170049,,F,090049.000,A,3244.5761,N,09708.8238,W,0.00,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150828170119,,F,090119.000,A,3244.5760,N,09708.8238,W,0.03,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150828170149,,F,090149.000,A,3244.5760,N,09708.8238,W,0.01,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150828170219,,F,090219.000,A,3244.5749,N,09708.8235,W,0.02,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150828170249,,F,090249.000,A,3244.5744,N,09708.8242,W,0.03,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150828170319,,F,090319.000,A,3244.5744,N,09708.8241,W,0.02,266.92,,0,0,,,;
			# imei:359710049084651,tracker,150830212601,,F,132601.000,A,3244.5570,N,09708.8175,W,0.01,0.00,,0,0,,,

			# break it into messages
			messages = []

			# parse the fields
			@esn = fields.shift.remove! 'imei:'
			device_name = fields.shift

			# get the time -- add '20' in front for the year 20XX
			@occurred_at = Time.parse("20#{fields.shift}").utc()	

			fields.shift #empty
			letter_F = fields.shift
			@external_message_id = fields.shift
			letter_A = fields.shift
			
			lat_hhmmm = fields.shift
			n_or_s = fields.shift
			lng_hhmmm = fields.shift
			e_or_w = fields.shift

			latitude = Coords::Convert.hhmmmToLatLng(lat_hhmmm[0..1], lat_hhmmm[2..-1], n_or_s)
			longitude = Coords::Convert.hhmmmToLatLng(lng_hhmmm[0..2], lng_hhmmm[3..-1], e_or_w)

			# unused
			unknown = fields.shift
			azimuth = fields.shift
			fields.shift #empty
			zero = fields.shift
			zero = fields.shift
			fields.shift #empty
			fields.shift #empty
			fields.shift #empty

			# location
			loc_msg = getLocationMsg(latitude, longitude, {
				azimuth: azimuth
			})
			messages << loc_msg if loc_msg

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
			value = battery_value	# 0 -> 100

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