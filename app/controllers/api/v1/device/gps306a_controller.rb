# frozen_string_literal: true

class Api::V1::Device::Gps306aController < ApplicationController

	skip_before_action :verify_authenticity_token

	# examples
	# imei:359710049084651,tracker,150828170219,,F,090219.000,A,3244.5749,N,09708.8235,W,0.02,266.92,,0,0,,,;
	def decode()

		begin

			csv = params[:payload]

			# remove trailing ;
			csv.remove! ';'

			# split into components
			fields = csv.split(',', -1)
			messages = handleLocationMessage fields	

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


	def handleLocationMessage(fields)

		puts "#{fields}"

		verifyMessage(fields)

		decode = Gps306a::Decoder.new
		parsed_messages = decode.locationMessage(fields)

		return parsed_messages.map do |message|
			message.serializable_hash(:only => ['esn', 'source', 'value', 'meta', 'occurred_at'])
		end

	end

	def verifyMessage(fields)

		if fields.length != 19
			raise "wrong # of fields: #{fields.length} expected exactly 19"
		end

		# @jake todo: more validation

	end

	def respond(res)
		respond_to do |format|
			format.json { render json: res }
			format.xml { render json: res }
		end
	end

end
