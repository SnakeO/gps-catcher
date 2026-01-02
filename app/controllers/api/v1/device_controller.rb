# frozen_string_literal: true

require 'yaml'

class Api::V1::DeviceController < ApplicationController

	skip_before_action :verify_authenticity_token

	# decode into messages
	def messages

		allowed_devices = [
			'gl200', 
			'smartoneb',
			'gps306a',
			'spot',
		]

		if !allowed_devices.include? params[:device]
			return respond({
				success: false,
				code: 	'invalid_device',
				message: "The device #{params[:device]} can not be handled."
			})
		end

		# call the class method
		data = send(params[:device])
		
		return respond({
			success: true,
			data: data
		})
		
	end

	def gl200
		return [
			{
				type: 'location'
			},
			{
				type: 'battery'
			}
		]
	end

	def respond(res)
		respond_to do |format|
			format.json { render json: res }
			format.xml { render json: res }
		end
	end

end
