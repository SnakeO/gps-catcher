module Xexun
	module Tk1022
		class Worker
			include Sidekiq::Worker
			sidekiq_options :retry => 5

			# examples
			# (027043507615BR00151128A3244.5717N09708.8245W000.20533560.000000000000L00000000)
			def perform(origin_message_id)

				msg_obj = nil
			 
				begin

					msg_obj = Xexun::Tk1022::Message.find origin_message_id
					raw = msg_obj.raw

					# remove opening and closing parens
					raw.remove! '('
					raw.remove! ')'
					
					success = handleLocationMessage raw, msg_obj

					# back to stage 0 if it was unsuccessful
					msg_obj.processed_stage = success ? 2 : 0
					msg_obj.extra = success ? 'success' : '1 or more parsed messages failed'	

				rescue Exception => e

					puts "ERROR handling Xexun::Tk1022 origin_message_id (#{origin_message_id}): #{e}"

					msg_obj.extra = "ERROR handling: #{e}"
					msg_obj.processed_stage = 0

				end

				msg_obj.save()

			end


			def handleLocationMessage(raw, origin_message)

				puts "#{raw}"

				verifyMessage(raw)

				decode = Xexun::Tk1022::Decoder.new
				parsed_messages = decode.locationMessage(raw)

				send_res = true

				parsed_messages.each_with_index do |parsed_message, i|

					# we're using the occurred_at of the inserted location msg since there's no separate time attached to this device
					parsed_message.occurred_at = origin_message.created_at.utc
					parsed_message.origin_message_type = 'Xexun::Tk1022'
					parsed_message.origin_message_id = origin_message.id
					parsed_message.info = nil
					parsed_message.save

					send_res = send_res && parsed_message.sendToPostgres()

				end

				send_res

			end

			def verifyMessage(raw)

				if raw[0] != '0'
					raise "expected first character to be a 0, instead got: #{raw[0]}"
				end

				if raw.scan('.').length != 4
					raise "wrong # of dots: #{raw.scan('.').length} expected exactly 4"
				end

				if raw.length != 78
					raise "wrong length: #{raw.length} expected exactly 78 characters"
				end


				# @jake todo: more validation

			end

		end
	end
end