class Gl300Controller < ApplicationController

	skip_before_action :verify_authenticity_token

	def work
		Queclink::Gl300::Message.where(processed_stage:1).each do |message|
			
			if message.status == 'ok'
				message.processed_stage = 1
				Queclink::Gl300::Worker.perform_async(message.raw, message.id)
			else
				message.processed_stage = -1 # mark this row as 'skipped'
			end

			message.save

		end

		render plain: 'done'
	end

	# receive a message
	def msg

		msg = Queclink::Gl300::Message.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Queclink::Gl300::Worker.perform_async(msg.raw, msg.id)

		render plain: 'ok'
	end

end
