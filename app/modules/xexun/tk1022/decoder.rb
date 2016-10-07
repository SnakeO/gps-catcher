require 'json'

module Xexun
	module Tk1022
		class Decoder

			# decode location message string into messages
			def locationMessage(str)

				# EXAMPLES
				# ==================================
				# 027043507615BR00151128A3244.5722N09708.8233W000.00525560.000000000000L00000000
				# 027043507615BR00151128A3244.5720N09708.8253W000.20526460.000000000000L00000000
				# 027043507615BR00151128A3244.5715N09708.8240W000.10527560.000000000000L00000000
				# 027043507615BR00151128A3244.5708N09708.8266W000.80529560.000000000000L00000000
				# 027043507615BR00151128A3244.5752N09708.8216W001.10855560.000000000000L00000000

				# break it into messages
				messages = []

				@external_message_id = Digest::MD5.hexdigest(str)

				# fields
				# input of
				# 027043507615BR00151128A3244.5752N09708.8216W001.10855560.000000000000L00000000
				# will produce output of fields array:
				# 1:"027043507615" 2:"151128" 3:"32" 4:"44.5752" 5:"N" 6:"097" 7:"08.8216" 8:"W" 9:"001.10855560"
				fields = /([\d]{12})BR[\d]{2}([\d]{6})A([\d]{2})([\d]{2}.[\d]{4})(N|S)([\d]{3})(\d{2}.[\d]{4})(E|W)([\d]{3}.[\d]{8})/.match(str)

				# parse the fields
				@esn = fields[1]
				ymd = fields[2]

				lat_hh 	= fields[3]
				lat_mmm	= fields[4]
				lat_hem	= fields[5]	#hemisphere

				lng_hh		= fields[6]
				lng_mmm		= fields[7]
				lng_hem		= fields[8]

				azimuth 		= fields[9]

				lat = Coords::Convert.hhmmmToLatLng(lat_hh, lat_mmm, lat_hem)
				lng = Coords::Convert.hhmmmToLatLng(lng_hh, lng_mmm, lng_hem)

				# location
				loc_msg = getLocationMsg(lat, lng, {
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

				batt_msg.esn = @esn

				batt_msg
			end

		end
	end
end