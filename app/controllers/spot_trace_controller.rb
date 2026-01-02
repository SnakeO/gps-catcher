class SpotTraceController < ApplicationController

	skip_before_action :verify_authenticity_token

	"""
	def work
		SpotTraceMessage.where(processed_stage:0).each do |message|
			
			if message.status == 'ok'
				message.processed_stage = 1
				SpotTraceWorker.perform_async(message.raw, message.id)
			else
				message.processed_stage = -1 # mark this row as 'skipped'
			end

			message.save

		end

		render plain: 'done'
	end
	"""

	# receive a message
	def msg

		# @jake todo (see SPOT_CommercialAccountDataAccessUserGuide.pdf page 12)
		# THey send headers like this with their messages
		# Authorization: WSSE profile="UsernameToken"
		# X-WSSE: UsernameToken Username="sdfwew23q",
		# PasswordDigest="quR/EWLAV4xLf9Zqyw4pDmfV9OY=",
		# Nonce="d36e316282959a9ed4c89851497a717f", Created="2008-06-
		# 13T16:41:32Z"
		
		begin
			doc  = Nokogiri::XML(request.raw_post) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end
		rescue Exception => e

			msg = SpotTraceMessage.new
			msg.raw = request.raw_post
			msg.status = 'malformed'
			msg.extra = "#{e}"
			msg.processed_stage = -1
			msg.save

			return render plain: "malformed xml: #{e}"
		end

		msg = SpotTraceMessage.new
		msg.raw = doc.to_s
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		SpotTraceWorker.perform_async(msg.raw, msg.id)

		render plain: 'ok'
	end

end