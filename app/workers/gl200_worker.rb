class Gl200Worker
	include Sidekiq::Worker
	sidekiq_options :retry => 5

	# examples
	# +RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,180.4,-97.145723,32.742709,20150526021641,,,,,,89,20150526021819,129B$
	def perform(csv, origin_message_id)

		msg_obj = nil
	 
		begin

			msg_obj = Gl200Message.find origin_message_id

			# skip messages that recently failed so we don't keep trying to re-process it every minute
			# if (msg_obj.created_at != msg_obj.updated_at) && (Time.now - 1.hours < msg_obj.updated_at)
			# 	puts "skipping message"
			# 	msg_obj.processed_stage = 0
			# 	msg_obj.save
			# 	return
			# end

			# remove trailing $
			csv.remove! '$'

			# split into components
			fields = csv.split(',', -1)
			header = fields.shift.split ':'

			header_via = header[0]
			header_type = header[1]

			if header_via != '+RESP' && header_via != '+BUFF'
				raise "Unknown header: #{header_via}"
			end

			puts "message header type: #{header_type}"

			position_report_headers = ['GTFRI', 'GTGEO', 'GTSPD', 'GTSOS', 'GTRTL', 'GTPNL', 'GTNMR', 'GTDIS', 'GTDOG', 'GTIGL', 'GTPFL']

			if position_report_headers.include? header_type
				# timed report, or if a user turned around (if that feature is enabled)
				success = handlePositionReport header_type, fields, origin_message_id
			elsif header_type == 'GTGSM'
				# The report of the information of the service cell and neighbor cells
			elsif header_type == 'GTINF'
				# general information report (contains battery info, ignition/movement state, last GPS fix time, mileage)
			else
				raise "Unknown message header_type #{header_type}"
			end

			# back to stage 0 if it was unsuccessful
			msg_obj.processed_stage = success ? 2 : 0
			msg_obj.extra = success ? 'success' : '1 or more parsed messages failed'	

		rescue Exception => e

			puts "ERROR handling gl200 origin_message_id (#{origin_message_id}): #{e}"

			msg_obj.extra = "ERROR handling: #{e}"
			msg_obj.processed_stage = 0

		end

		msg_obj.save()

	end


	def handlePositionReport(header_type, fields, origin_message_id)

		puts "#{header_type}|#{fields}"

		verifyPositionReport(fields)

		decode = Gl200::Decoder.new
		parsed_messages = decode.positionReport(fields)

		send_res = true

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.origin_message_type = 'gl200'
			parsed_message.origin_message_id = origin_message_id
			parsed_message.info = nil
			parsed_message.save

			send_res = send_res && parsed_message.sendToPostgres()

		end

		send_res

	end

	def verifyPositionReport(fields)

		if fields.length < 21
			raise "too few fields: #{fields.length} expected at least 21"
		end

		# @jake todo: check num_locations value, and append_mask value, and compare that with the length of the fields

	end

end