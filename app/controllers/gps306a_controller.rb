# OBD II tracker
class Gps306aController < ApplicationController

	skip_before_action :verify_authenticity_token

	# receive a message
	def msg

		# ignore the 'heartbeat' it sends when it's just the IMEI
		if request.raw_post.split(',').length == 1
			render :text => 'ok'
			return
		end

		msg = Gps306aMessage.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Gps306aWorker.perform_async(msg.id)

		render :text => 'ok'
	end

end
