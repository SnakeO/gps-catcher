class Gl300maController < ApplicationController

	skip_before_action :verify_authenticity_token

	def work
		Queclink::Gl300ma::Message.where(processed_stage:1).each do |message|
			
			if message.status == 'ok'
				message.processed_stage = 1
				Queclink::Gl300ma::Worker.perform_async(message.raw, message.id)
			else
				message.processed_stage = -1 # mark this row as 'skipped'
			end

			message.save

		end

		render :text => 'done'
	end

	# receive a message
	def msg

		msg = Queclink::Gl300ma::Message.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Queclink::Gl300ma::Worker.perform_async(msg.raw, msg.id)

		render :text => 'ok'
	end

end
