class GeofenceController < ApplicationController

	skip_before_action :verify_authenticity_token

	# check to see if any geofences have been crossed
	def check

		last_location_msg_checked = Setting.where(key:'last_location_msg_checked').first
		start_id = last_location_msg_checked.value.to_i
		start_id = 0

		num = 0
		LocationMsg.where('id > :id', {id:start_id}).each_with_index do |message, i|

			Geofence.where(esn:message.esn).each do |fence|

				begin

					# has this fence been deleted already?
					# next if fence.deleted_at != nil

					# is this a single-alert fence that's already fired?
					# next if fence.is_single_alert && fence.num_alerts_sent > 0

					# make sure the fence existed when this location point happened
					# next if fence.created_at > message.occurred_at

					is_inside = fence.contains(message.point.y, message.point.x)
					last_fence_state = FenceState.where(esn:message.esn).where(geofence_id:fence.id).order(occurred_at:'DESC').first

					curr_fence_state = FenceState.new({
						geofence: fence,
						location_msg: message,
						occurred_at: message.occurred_at,
						state: is_inside ? 'i' : 'o',
						esn: message.esn
					})

					# very first state found?
					if last_fence_state == nil 
						# then just record it and be on our way
						curr_fence_state.save
						next
					end

					# no change in state? then keep on goin
					next if curr_fence_state.state == last_fence_state.state

					# entered the fence?
					fence_alert = nil

					if (fence.alert_type == 'i' || fence.alert_type == 'b') && last_fence_state.state == 'o' && curr_fence_state.state == 'i'
						puts "ALERT - #{curr_fence_state.esn} ENTERED FENCE #{curr_fence_state.geofence_id} @ #{curr_fence_state.occurred_at} (#{fence.alert_type})"
						
						fence_alert = FenceAlert.new({
							geofence: curr_fence_state.geofence,
							webhook_url: 'http://gps.tools/wp-admin/admin-ajax.php?action=Geofence/alert_webhook'
						})

						fence.num_alerts_sent += 1
					end

					# exited the fence?
					if (fence.alert_type == 'o' || fence.alert_type == 'b') && last_fence_state.state == 'i' && curr_fence_state.state == 'o'
						puts "ALERT - #{curr_fence_state.esn} EXITED FENCE #{curr_fence_state.geofence_id} @ #{curr_fence_state.occurred_at} (#{fence.alert_type})"
						
						fence_alert = FenceAlert.new({
							geofence: curr_fence_state.geofence,
							webhook_url: 'http://gps.tools/wp-admin/admin-ajax.php?action=Geofence/alert_webhook'
						})

						fence.num_alerts_sent += 1
					end

					curr_fence_state.save

					if fence_alert != nil
						fence_alert.fence_state = curr_fence_state
						fence_alert.save 
					end

					fence.save

				rescue Exception => e
					# DevAlert
					puts "Error checking geofence for alerts #{e}"
					puts e.backtrace
				end

			end
			
			# bookkeeping
			last_location_msg_checked.value = message.id
			num = i
		end

	#	last_location_msg_checked.save

		render :text => "processed #{num} location messages"
	end

	# run the workers
	def work
		FenceAlert.where(processed_stage:0).limit(1).each do |alert|

			# mark it as 'being processed'
			alert.processed_stage = 1
			alert.save

			FenceAlertWorker.perform_async(alert.id)
		end

		render :text => 'done'
	end

end
