# frozen_string_literal: true

require 'json'

module Gl200
	class Decoder

		# decode Position Report fields into messages
		def positionReport(fields)

			# EXAMPLES
			# ==================================
			# +RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,196.5,-97.147099,32.742800,20150526000805,,,,,,91,20150526000956,1291$
			# +RESP:GTSPD,020301,135790246811220,,0,0,1,1,4.3,92,70.0,121.354335,31.222073,20090214013254,0460,0000,18d8,6141,00,,20090214093254,11F0$
			# +RESP:GTSOS,020301,135790246811220,,0,0,1,1,4.3,92,70.0,121.354335,31.222073,20090214013254,0460,0000,18d8,6141,00,,20090214093254,11F0$
			# +RESP:GTRTL,020301,135790246811220,,0,0,1,1,4.3,92,70.0,121.354335,31.222073,20090 214013254,0460,0000,18d8,6141,00,,20090214093254,11F0$
			# +RESP:GTPNL,020301,135790246811220,,0,0,1,1,4.3,92,70.0,121.354335,31.222073,20090 214013254,0460,0000,18d8,6141,00,,20090214093254,11F0$

			# 	Protocol Version = 02010D
			# 	Unique ID = 867844001851958
			# 	Device Name = 
			# 	Report ID/ Append Mask = 0
			# 	Report Type = 0	 // 0 = scheduled report, 1 = user turned around
			# 	Number = 1 // number of points.. (there could be up to 15) If there are more than 1 point in the report, information from <GPS accuracy> to <Odo mileage> is repeated for each point.
			# 	 GPS Accuracy = 2 // smaller = higher precision
			# 	Speed = 0.0 // sometimes -1?
			# 	Azimuth = 2
			# 	Altitude = 139.4
			# 	longitude = -97.147163
			# 	latitude = 32.742993
			# 	gps utc time = 20150526000208
			# 	mcc = 
			# 	mnc = 
			# 	lac =
			# 	cell id =
			# 	 odo mileage =
			# 	battery percentage = 91
			# 	io status = // this exists only if the append mask is set to 1
			# 	send time = 20150526000356
			# 	count number = 128E

			# break it into messages
			messages = []

			# parse the fields
			@external_message_id = fields.pop  # pop, not shift

			protocol_version = fields.shift
			@esn = fields.shift
			device_name = fields.shift
			append_mask = fields.shift.to_i
			report_type = fields.shift.to_i 	# 0 = scheduled report, 1 = user turned around
			num_points = fields.shift.to_i 

			# number of points.. (there could be up to 15) If there are more than 1 point in the report, information from <GPS accuracy> to <Odo mileage> is repeated for each point.
			num_points.times do |i|

				gps_accuracy = fields.shift.to_i
				speed = fields.shift.to_f
				azimuth = fields.shift.to_f
				altitude = fields.shift.to_f
				longitude = fields.shift.to_f
				latitude = fields.shift.to_f
				@occurred_at = Time.parse(fields.shift).utc()	# e.g 20150526000208 

				mcc = fields.shift		# unused..
				mnc = fields.shift		# unused..
				lac = fields.shift		# unused..
				cell_id = fields.shift	# unused..

				odo_mileage = fields.shift

				# location
				loc_msg = getLocationMsg(latitude, longitude, {
					confidence: (50 - gps_accuracy) / 50.0,	# max value of 50, lower == better. So a gps_accuracy of 0 will result in 1 confidence, gp_accuracty of 40 will result in 0.2 confidence
					speed: speed, 									# km /hr
					altitude: altitude,
					gps_accuracy: gps_accuracy,
					odometer: odo_mileage
				})
				messages << loc_msg if loc_msg
			end

			# battery
			batt_value = fields.shift.to_i
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