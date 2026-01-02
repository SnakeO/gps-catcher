# Mini GPS Tracker
class SmartBdgpsController < ApplicationController

	skip_before_action :verify_authenticity_token

	# receive a message
	def msg
		
		msg = Smart::Bdgps::Message.new
		msg.raw = request.raw_post
		msg.status = 'ok'
		msg.extra = nil
		msg.processed_stage = 1
		msg.save

		Smart::Bdgps::Worker.perform_async(msg.id)

		render plain: 'ok'
	end

end
