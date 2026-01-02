# frozen_string_literal: true

class Api::V1::Device::SmartOneBController < ApplicationController

	skip_before_action :verify_authenticity_token

	def decode()

		begin

			xml = params[:payload]

			doc  = Nokogiri::XML(xml) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end

			# standard or privisioning?
			msg_type = doc.css('stuMessages').length ? 'stu' : 'prv'

			if( msg_type == 'stu' )
				messages = handleSTUs(doc)
			else 
				raise "PRV messages are unsupported"
			end

		rescue Exception => e

			return respond({
				success: false,
				message: "#{e}"
			})

		end

		respond({
			success: true,
			data: {
				messages: messages
			}
		})

	end

	def handleSTUs(doc)
		external_message_id = doc.css('stuMessages').attr('messageID').value
		
		all_messages = []

		doc.css('stuMessage').each do |stu| 
			# if any handleSTU fails, then success will be false
			all_messages << handleSTU(stu, external_message_id)
		end

		return all_messages.flatten
	end

	def handleSTU(doc, external_message_id)

		esn = doc.css('esn').text
	#	dateTime = doc.attr('timeStamp').value
		unix_timestamp = doc.css('unixTime').text.to_i
		
		# get the payload, remove the 0x
		payload = doc.css('payload').text
		payload.slice! "0x"

		payload_length = doc.css('payload').attr('length').value.to_i
		payload_encoding = doc.css('payload').attr('encoding').value	# assumed to be 'hex'

		verify(esn, payload, payload_length, payload_encoding)

		decode = Globalstar::Decoder.new
		parsed_messages = decode.payload(payload, external_message_id)

		parsed_messages.each_with_index do |parsed_message, i|

			parsed_message.occurred_at = Time.at(unix_timestamp).utc
			parsed_message.esn = esn
			
		end

		return parsed_messages.map do |message|
			message.serializable_hash(:only => ['esn', 'source', 'value', 'meta', 'occurred_at'])
		end

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

	def respond(res)
		respond_to do |format|
			format.json { render json: res }
			format.xml { render json: res }
		end
	end

end
