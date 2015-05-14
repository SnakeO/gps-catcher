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
				success = handleSTUs(doc, origin_message_id)
			else 
				msg_obj = PrvMessage.find origin_message_id
				handlePRVs(doc, origin_message_id)
			end

			# back to stage 0 if it was unsuccessful
			msg_obj.processed_stage = success ? 2 : 0
			msg_obj.extra = success ? '' : '1 or more parsed messages failed'
			

		rescue Exception => e

			msg_obj.extra = "ERROR handling: #{e}"
			msg_obj.processed_stage = 0
			
			puts msg_obj.extra

		end

		msg_obj.save()
		#PGConn.close()

	end

	def handleSTUs(doc, origin_message_id)
		external_message_id = doc.css('stuMessages').attr('messageID').value
		
		success = true

		doc.css('stuMessage').each do |stu| 
			# if any handleSTU fails, then success will be false
			success = success && handleSTU(stu, origin_message_id, external_message_id)
		end

		return success
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

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.occurred_at = Time.at(unix_timestamp).utc
			parsed_message.origin_message_type = 'stu'
			parsed_message.origin_message_id = origin_message_id
			parsed_message.esn = esn
			parsed_message.num_tries += 1
			parsed_message.save

			self.sendParsedMessageToPostgres(parsed_message)

		end

	end

	# save to postgres
	# http://exposinggotchas.blogspot.com/2011/02/activerecord-migrations-without-rails.html
	def sendParsedMessageToPostgres(parsed_message)

		begin
			sql = 'opening pg connection...'	# for the sake of our 'rescue'
			pg = PGConn.get

			if parsed_message.source == 'location'

				latlng = parsed_message.value.split(',')
				lat = latlng[0]
				lng = latlng[1]

				# location messages get their lat/lng stored as a point
				sql = "INSERT INTO location_msg (esn,occurred_at,geom,meta,unique_msg_id) VALUES (
					'#{parsed_message.esn}', 
					'#{parsed_message.occurred_at.strftime('%Y-%m-%d %H:%M:%S')}',
					ST_GeomFromText('POINT(#{lng} #{lat})', 4269),
					'#{parsed_message.meta}',
					'#{parsed_message.message_id}'
				);"
				
			else

				# location messages get their lat/lng stored as a point
				sql = "INSERT INTO info_msg (esn,occurred_at,source,value,meta,unique_msg_id) VALUES (
					'#{parsed_message.esn}', 
					'#{parsed_message.occurred_at.strftime('%Y-%m-%d %H:%M:%S')}',
					'#{parsed_message.source}',
					'#{parsed_message.value}',
					'#{parsed_message.meta}',
					'#{parsed_message.message_id}'
				);"

			end

			pg.exec sql
			parsed_message.is_sent = true

		rescue Exception => e
				
			# log the error
			parsed_message.is_sent = false
			parsed_message.info = "PG INSERT ERROR: #{e} - #{sql}"
			puts parsed_message.info
			parsed_message.save

			return false

		end

		return true

	end

	def handlePRVs(doc, origin_message_id)
		puts "skipping PRV"
		return true
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