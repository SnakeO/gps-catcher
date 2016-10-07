class Api::V1::Device::Gl200Controller < ApplicationController

	skip_before_action :verify_authenticity_token

	# examples
	# +RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,180.4,-97.145723,32.742709,20150526021641,,,,,,89,20150526021819,129B$
	def decode()

		begin
			
			csv = params[:payload]

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

			position_report_headers = ['GTFRI', 'GTGEO', 'GTSPD', 'GTSOS', 'GTRTL', 'GTPNL', 'GTNMR', 'GTDIS', 'GTDOG', 'GTIGL', 'GTPFL']

			if position_report_headers.include? header_type
				# timed report, or if a user turned around (if that feature is enabled)
				messages = parsePositionReport fields
			else
				raise "Message type #{header_type} is not currently handled"
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


	def parsePositionReport(fields)

		verifyPositionReport(fields)

		decode = Gl200::Decoder.new
		parsed_messages = decode.positionReport(fields)

		return parsed_messages.map do |message|
			message.serializable_hash(:only => ['esn', 'source', 'value', 'meta', 'occurred_at'])
		end

	end

	def verifyPositionReport(fields)

		if fields.length < 21
			raise "too few fields: #{fields.length} expected at least 21"
		end

		# @jake todo: check num_locations value, and append_mask value, and compare that with the length of the fields

	end

	def respond(res)
		respond_to do |format|
			format.json { render json: res }
			format.xml { render json: res }
		end
	end

end
