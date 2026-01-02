# Mini GPS Tracker
class XexunTk1022Controller < ApplicationController

	skip_before_action :verify_authenticity_token

	# receive a message
	def msg

		# ignore the 'heartbeat' it sends when it's just the IMEI
		if request.raw_post.split('.').length == 1
			render plain: 'ok'
			return
		end

		msg = Xexun::Tk1022::Message.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Xexun::Tk1022::Worker.perform_async(msg.id)

		render plain: 'ok'
	end

end
