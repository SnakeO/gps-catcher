class SpotTraceWorker
	include Sidekiq::Worker
	sidekiq_options :retry => 5

	def perform(xml, origin_message_id)

		msg_obj = nil
	 
		begin

			msg_obj = SpotTraceMessage.find origin_message_id

			# skip messages that recently failed so we don't keep trying to re-process it every minute
			# @jake todo: this needs ot be in a 'last_processed' field not 'updated_at'
			# if (msg_obj.created_at != msg_obj.updated_at) && (Time.now - 1.hours < msg_obj.updated_at)
			# 	puts "skipping message"
			# 	msg_obj.processed_stage = 0
			# 	msg_obj.save
			# 	return
			# end

			doc  = Nokogiri::XML(xml) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end

			header = doc.css('header')
			messages = doc.css('message')
			errors = header.css('errors')

			if errors.length > 0 
				raise "Error Messages Detected"
			end

			success = handleMessages(messages, origin_message_id)

			# back to stage 0 if it was unsuccessful
			msg_obj.processed_stage = success ? 2 : 0
			msg_obj.extra = success ? 'success' : '1 or more parsed messages failed'	

		rescue Exception => e

			puts "ERROR handling spot_trace origin_message_id (#{origin_message_id}): #{e} "
			puts e.backtrace

			msg_obj.extra = "ERROR handling: #{e}\n\n#{e.backtrace}"
			msg_obj.processed_stage = 0

		end

		msg_obj.save()

	end

	def handleMessages(messages, origin_message_id)
		success = true

		messages.each do |message|

			verifyMessage(message)

			# skip test messages
			next if message.css('messageType').text() == 'TEST'
			success = success && handleMessage(message, origin_message_id)
		end

		success
	end


	def handleMessage(message, origin_message_id)

		decode = SpotTrace::Decoder.new
		parsed_messages = decode.message(message)

		send_res = true

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.origin_message_type = 'spot_trace'
			parsed_message.origin_message_id = origin_message_id
			parsed_message.info = nil
			parsed_message.save

			send_res = send_res && parsed_message.sendToPostgres()

		end

		send_res

	end

	def verifyMessage(message)
		# some required fields
		['id', 'esn', 'messageType', 'timestamp', 'timeInGMTSecond', 'latitude', 'longitude'].each do |required|
			raise "missing #{required}" if message.css(required).length == 0
		end
	end

end