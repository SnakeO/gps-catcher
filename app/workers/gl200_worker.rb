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
			fields = csv.split ','
			header = fields.shift.split ':'

			if header[0] != '+RESP' && header[0] != '+BUFF'
				raise "Unknown header: #{header[0]}"
			end

			puts "message header: #{header[1]}"
			
			if header[1] == 'GTFRI'
				# timed report, or if a user turned around (if that feature is enabled)
				success = handleGTFRI fields, origin_message_id
			elsif header[1] == 'GTGSM'
				# The report of the information of the service cell and neighbor cells
			else
				raise "Unknown message type #{header[1]}"
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


	def handleGTFRI(fields, origin_message_id)

		puts "#{fields}"

		verifyGTFRI(fields)

		decode = Gl200::Decoder.new
		parsed_messages = decode.GTFRI(fields)

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

	def verifyGTFRI(fields)

		if fields.length < 21
			raise "too few fields: #{fields.length} expected at least 21"
		end

		# @jake todo: check num_locations value, and append_mask value, and compare that with the length of the fields

	end

end