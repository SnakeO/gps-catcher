require 'json'

module Globalstar
	class Decoder

		def payload(payload, external_message_id)

			@external_message_id = external_message_id

			# Example
			# --------------------------------------
			# 0x002E914EBAEAE84A08
			# 0x00 2E 91 4E BA EA E8 4A 08
			# 00|0|0| 00|00| 0010 1110 1001 0001 0100 1110| 1011 1010 1110 1010 1110 1000| 0100| 1010| 000|0 1|0|0|0
			# 
			# Breakdown
			# --------------------------------------
			# Type = 2 bits
			# Battery Good? = 1 bit
			# GPS Data Valid? = 1 bit
			# Missed Input = 2 bits
			# GPS Fail Counter = 2 bits
			# Latitude = 24 bits
			#     Latitude = LAT * (90.0/2**23)
			# Longitude = 24 bits
			#     Longitude = LNG * (180.0/2**23)
			# Input Status = 4 bits
			# Message Sub-Type = 4 bits
			# Unused = 3 bits
			# Vibration Triggered Message = 1 bit
			# Vibration Bit = 1 bit
			# 2D = 1 bit
			# Motion = 1 bit
			# Fix Confidence Bit = 1 bit

			# # of bits (it is 72)
			num_bits = payload.length * 4

			# convert from hex to a binary string and pad the left with 0's
			bin = payload.to_i(16).to_s(2).rjust(num_bits, '0')

			# 72 bits total
			type              = bin[0, 2].convert_base(2,10)
			good_battery      = bin[2, 1].convert_base(2,10)
			gps_data_valid    = bin[3, 1].convert_base(2,10)
			missed_input      = bin[4, 2].convert_base(2,10)
			gps_fail_counter  = bin[6, 2].convert_base(2,10)
			lat               = bin[8, 24]
			lng               = bin[32, 24]
			input_status      = bin[56, 4].convert_base(2,10)
			message_sub_type  = bin[60, 4].convert_base(2,10)
			unused            = bin[64, 3].convert_base(2,10)
			vib_trig_msg      = bin[67, 1].convert_base(2,10)
			vib_bit           = bin[68, 1].convert_base(2,10)
			twoD              = bin[69, 1].convert_base(2,10)
			in_motion         = bin[70, 1].convert_base(2,10)
			fix_confidence_bit = bin[71, 1].convert_base(2,10)

			# lat/lng are two's compliment signed numbers
			if gps_data_valid == 0	# 0 means valid gps_data
				latitude = latFromBin(lat)
				longitude = lngFromBin(lng)
			end

			puts "type #{type}\n"
			puts "good_battery #{good_battery}\n"
			puts "gps_data_valid #{gps_data_valid}\n"
			puts "missed_input #{missed_input}\n"
			puts "gps_fail_counter #{gps_fail_counter}\n"
			puts "lat #{latitude}\n"
			puts "lng #{longitude}\n"
			puts "input_status #{input_status}\n"
			puts "message_sub_type #{message_sub_type}\n"
			puts "unused #{unused}\n"
			puts "vib_trig_msg #{vib_trig_msg}\n"
			puts "vib_bit #{vib_bit}\n"
			puts "twoD #{twoD}\n"
			puts "in_motion #{in_motion}\n"
			puts "fix_confidence_bit #{fix_confidence_bit}\n\n"

			# break it into messages
			messages = []

			# battery
			batt_msg = getBatteryMsg(good_battery)
			messages << batt_msg

			# location
			loc_msg = getLocationMsg(gps_data_valid, latitude, longitude, {
				twoD: twoD,
				is_in_motion: in_motion,
				is_confident: (fix_confidence_bit == 0) ? 1 : 0	# 0 means high confidence
			})
			messages << loc_msg if loc_msg

			# sub-type
			sub_type_msg = msgFromSubType(message_sub_type)
			messages << sub_type_msg if sub_type_msg

			# in motion? (1 == yes)
			in_motion_msg = getInMotionMsg(in_motion)
			messages << in_motion_msg

			messages
		end

		def latFromBin(bin)
			# bin is a two's compliment signed number
			if bin[0] == '1'
				lat = -(bin.flipBits().convert_base(2,10) + 1)
			else
				lat = bin.convert_base(2,10)
			end

			lat * (90.0/(2**23))
		end

		def lngFromBin(bin)
			# bin is a two's compliment signed number
			if bin[0] == '1'
				lng = -(bin.flipBits().convert_base(2,10) + 1)
			else
				lng = bin.convert_base(2,10)
			end

			lng * (180.0/(2**23))
		end

		def msgFromSubType(message_sub_type)

			if message_sub_type == 0
				# this is a regular "location" message 
				# which is sent on a regular interval
				
			elsif message_sub_type == 1
				# the device was turned on
				return getTurnedOnMsg('on')

			elsif message_sub_type == 2
				# change of location alert message;
				# device left it's Change of Location area
				
			elsif message_sub_type == 3
				# This is the message that will be transmitted upon the 
				# change of state of the inputs if enabled and as selected 
				# by the user Input 1 open, input 1 closed, input 1 both, 
				# input 2 open, input 2 closed, input 2 both.
				# 
				# The 'input_status' variable indicates which input changed state 
				# to trigger the message and also reports the states of both inputs.
			
			elsif message_sub_type == 4
				# This is the message that is transmitted when the user has selected for 
				# an undesired input state to cause a different report rate. When this Mode 
				# is enabled, the user defined Undesired Input State report rate supersedes 
				# the At Rest and In Motion report rates when the input(s) is (are) in an undesired state.
				# 
				# The 'input_status' variable will indicate which input(s) are in the 
				# undesired state and triggering the Undesired Input State report rate.
			
			elsif message_sub_type == 5
				# The Re-Center message is transmitted when Reduced Messaging Mode is selected 
				# and the SMARTONE re-centers (automatically sets a new Change of Location Area)
			
			end

			return nil

		end

		def getTurnedOnMsg(power_value)

			source = 'powered'
			value = power_value

			# already exists?
			turned_on_msg = ParsedMessage.findExisting(@external_message_id, source, value)
			return turned_on_msg if turned_on_msg != nil

			turned_on_msg = ParsedMessage.new
			turned_on_msg.source = source
			turned_on_msg.value = power_value

			turned_on_msg
		end

		def getBatteryMsg(good_battery)

			source = 'battery'
			value = (good_battery == 0) ? 'g' : 'b'

			# already exists?
			batt_msg = ParsedMessage.findExisting(@external_message_id, source, value)
			return batt_msg if batt_msg != nil

			batt_msg = ParsedMessage.new
			batt_msg.source = source
			batt_msg.value = value

			batt_msg
		end

		def getLocationMsg(gps_data_valid, latitude, longitude, meta)
			return nil if gps_data_valid == 1	# 0 means INVALID gps_data

			source = 'location'
			value = "#{latitude},#{longitude}"
			
			# already exists?
			loc_msg = ParsedMessage.findExisting(@external_message_id, source, value, JSON.generate(meta))
			return loc_msg if loc_msg != nil

			loc_message = ParsedMessage.new
			loc_message.source = source
			loc_message.value = value
			loc_message.meta = JSON.generate(meta)

			loc_message
		end

		def getInMotionMsg(in_motion)

			source = 'is_in_motion'
			value = in_motion

			# already exists?
			in_motion_msg = ParsedMessage.findExisting(@external_message_id, source, value)
			return in_motion_msg if in_motion_msg != nil

			in_motion_msg = ParsedMessage.new
			in_motion_msg.source = source
			in_motion_msg.value = in_motion

			in_motion_msg
		end

	end
end