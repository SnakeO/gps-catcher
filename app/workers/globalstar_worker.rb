# frozen_string_literal: true

class GlobalstarWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 5

	def perform(xml, origin_message_id)

		msg_obj = nil
	 
		begin

			doc  = Nokogiri::XML(xml) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end

			# standard or privisioning?
			msg_type = doc.css('stuMessages').length ? 'stu' : 'prv'

			if( msg_type == 'stu' )
				msg_obj = StuMessage.find origin_message_id

				# skip messages that recently failed so we don't keep trying to re-process it every minute
				# if (msg_obj.created_at != msg_obj.updated_at) && (Time.now - 1.hours < msg_obj.updated_at)
				# 	msg_obj.processed_stage = 0
				# 	msg_obj.save
				# 	return
				# end

				success = handleSTUs(doc, origin_message_id)
			else 
				msg_obj = PrvMessage.find origin_message_id

				# skip messages that recently failed so we don't keep trying to re-process it every minute
				# if (msg_obj.created_at != msg_obj.updated_at) && (Time.now - 1.hours < msg_obj.updated_at)
				# 	msg_obj.processed_stage = 0
				# 	msg_obj.save
				# 	return
				# end

				handlePRVs(doc, origin_message_id)
			end

			# back to stage 0 if it was unsuccessful
			msg_obj.processed_stage = success ? 2 : 0
			msg_obj.extra = success ? 'success' : '1 or more parsed messages failed'	

		rescue Exception => e

			puts "ERROR handling origin_message_id (#{origin_message_id}): #{e}"

			msg_obj.extra = "ERROR handling: #{e}"
			msg_obj.processed_stage = 0
			
		#	puts msg_obj.extra

		end

		msg_obj.save()

	end

	def handleSTUs(doc, origin_message_id)
		external_message_id = doc.css('stuMessages').attr('messageID').value
		
		success = true

		doc.css('stuMessage').each do |stu| 
			# if any handleSTU fails, then success will be false
			success = success && handleSTU(stu, origin_message_id, external_message_id)
		end

		success
	end

	def handleSTU(doc, origin_message_id, external_message_id)

		esn = doc.css('esn').text
	#	dateTime = doc.attr('timeStamp').value
		unix_timestamp = doc.css('unixTime').text.to_i
		
		# get the payload, remove the 0x
		payload = doc.css('payload').text
		payload.slice! "0x"

		payload_length = doc.css('payload').attr('length').value.to_i
		payload_encoding = doc.css('payload').attr('encoding').value	# assumed to be 'hex'

		puts "#{esn} | #{external_message_id} | #{unix_timestamp} | #{payload_encoding} payload (#{payload_length}) #{payload}"

		verify(esn, payload, payload_length, payload_encoding)

		decode = Globalstar::Decoder.new
		parsed_messages = decode.payload(payload, external_message_id)

		send_res = true

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.occurred_at = Time.at(unix_timestamp).utc
			parsed_message.origin_message_type = 'stu'
			parsed_message.origin_message_id = origin_message_id
			parsed_message.esn = esn
			parsed_message.info = nil
			parsed_message.save

			send_res = send_res && parsed_message.sendToPostgres()

		end

		send_res

	end

	def handlePRVs(doc, origin_message_id)
		puts "skipping PRV"
		true
	end

	def verify(esn, payload, payload_length, payload_encoding)

		# globalstar sends messages that are 9 bytes long
		if payload_length != 9
			raise "Globalstar Payload Length expected to be reported as 9 bytes long. It is reported as #{payload_length} bytes"
		end

		# globalstar sends messages in hex format
		if payload_encoding != 'hex' 
			raise "Globalstar Payload expected to be hex encoded. It is reported as #{payload_encoding} encoding"
		end

		# make sure the payload length is what it says it is
		if payload.length/2 != payload_length 
			raise "Globalstar Payload Length reported as #{payload_length} bytes long. Actual length is #{payload.length/2} bytes"
		end

		# valid ESN
		if esn.length == 0
			raise "Invalid ESN"
		end

	end

end