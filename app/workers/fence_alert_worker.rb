# frozen_string_literal: true

require 'httparty'

class FenceAlertWorker
	include Sidekiq::Worker
	include HTTParty

	def perform(alert_id)

	 	alert = FenceAlert.find alert_id

	 	begin
			response = self.class.post(alert.webhook_url, body: {
				esn: alert.geofence.esn,
				state: alert.fence_state.state,
				pg_geofence_id: alert.geofence.id,
				lat: alert.fence_state.location_msg.point.latitude,
				lng: alert.fence_state.location_msg.point.longitude,
				occurred_at: alert.fence_state.occurred_at.to_s # todo: format this
			})

			alert.response_code = response.code
			alert.response = "#{response.headers.inspect}\n\n#{response.body}"

			alert.processed_stage = 2
			alert.sent_at = Time.now().utc()
			alert.save

		rescue Exception => e

			puts "ERROR handling: #{e}"
			alert.info = "ERROR handling: #{e}"
			alert.processed_stage = 0
			alert.save

		end
	end
end