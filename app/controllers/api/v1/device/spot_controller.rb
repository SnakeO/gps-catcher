# frozen_string_literal: true

class Api::V1::Device::SpotController < ApplicationController

	skip_before_action :verify_authenticity_token

	def decode()

		begin

			xml = params[:payload]

			doc  = Nokogiri::XML(xml) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end

			header = doc.css('header')
			messages = doc.css('message')
			errors = header.css('errors')

			if errors.length > 0 
				raise "Error Messages Detected"
			end

			messages = handleMessages(messages)

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

	def handleMessages(messages)
		all_messages = []

		messages.each do |message|
			all_messages << handleMessage(message)
		end

		return all_messages.flatten
	end


	def handleMessage(message)

		decode = SpotTrace::Decoder.new
		parsed_messages = decode.message(message)

		return parsed_messages.map do |message|
			message.serializable_hash(:only => ['esn', 'source', 'value', 'meta', 'occurred_at'])
		end

	end

	def verifyMessage(message)
		# some required fields
		['id', 'esn', 'messageType', 'timestamp', 'timeInGMTSecond', 'latitude', 'longitude'].each do |required|
			raise "missing #{required}" if message.css(required).length == 0
		end
	end

	def respond(res)
		respond_to do |format|
			format.json { render json: res }
			format.xml { render json: res }
		end
	end

end
