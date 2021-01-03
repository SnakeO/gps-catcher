class Gl200Controller < ApplicationController

	skip_before_action :verify_authenticity_token

	"""
	def work
		Gl200Message.where(processed_stage:0).each do |message|
			
			if message.status == 'ok'
				message.processed_stage = 1
				Gl200Worker.perform_async(message.raw, message.id)
			else
				message.processed_stage = -1 # mark this row as 'skipped'
			end

			message.save

		end

		render :text => 'done'
	end
	"""

	# receive a message
	def msg

		msg = Gl200Message.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Gl200Worker.perform_async(msg.raw, msg.id)

		render :text => 'ok'
	end

	# process an sms
	def sms

		msg = Gl200Message.new
		msg.raw = self.params[:Body]
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Gl200Worker.perform_async(msg.raw, msg.id)

		render :text => 'ok'
	end

end
