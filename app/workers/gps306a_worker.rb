class Gps306aWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 5

	# examples
	# imei:359710049084651,tracker,150828170219,,F,090219.000,A,3244.5749,N,09708.8235,W,0.02,266.92,,0,0,,,;
	def perform(origin_message_id)

		msg_obj = nil
	 
		begin

			msg_obj = Gps306aMessage.find origin_message_id
			csv = msg_obj.raw

			# remove trailing ;
			csv.remove! ';'

			# split into components
			fields = csv.split(',', -1)
			success = handleLocationMessage fields, origin_message_id

			# back to stage 0 if it was unsuccessful
			msg_obj.processed_stage = success ? 2 : 0
			msg_obj.extra = success ? 'success' : '1 or more parsed messages failed'	

		rescue Exception => e

			puts "ERROR handling gps306a origin_message_id (#{origin_message_id}): #{e}"

			msg_obj.extra = "ERROR handling: #{e}"
			msg_obj.processed_stage = 0

		end

		msg_obj.save()

	end


	def handleLocationMessage(fields, origin_message_id)

		puts "#{fields}"

		verifyMessage(fields)

		decode = Gps306a::Decoder.new
		parsed_messages = decode.locationMessage(fields)

		send_res = true

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.origin_message_type = 'gps306a'
			parsed_message.origin_message_id = origin_message_id
			parsed_message.info = nil
			parsed_message.save

			send_res = send_res && parsed_message.sendToPostgres()

		end

		send_res

	end

	def verifyMessage(fields)

		if fields.length != 19
			raise "wrong # of fields: #{fields.length} expected exactly 19"
		end

		# @jake todo: more validation

	end

end