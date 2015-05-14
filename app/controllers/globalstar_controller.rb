require 'net/ssh/gateway'

class GlobalstarController < ApplicationController

	skip_before_action :verify_authenticity_token

	def work
		StuMessage.where(processed_stage:0).each do |stu_message|
			
			if stu_message.status == 'ok'
				stu_message.processed_stage = 1
				GlobalstarWorker.perform_async(stu_message.raw, stu_message.id)
			else
				stu_message.processed_stage = -1 # mark this row as 'skipped'
			end

			stu_message.save

		end

		render :text => 'done'
	end

	# STU message
	def stu

		begin
			doc  = Nokogiri::XML(request.raw_post) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end
		rescue Exception => e

			msg = StuMessage.new
			msg.raw = request.raw_post
			msg.status = 'malformed'
			msg.extra = "#{e}"
			msg.save

			return render :text => stuResponse('FAIL', "malformed xml: #{e}", msg.id)
		end

		msg = StuMessage.new
		msg.raw = doc.to_s
		msg.status = 'ok'
		msg.save

		render :text => stuResponse('PASS', 'STU Message OK', msg.id)
	end
	
	def stuResponse(state, message='', message_id)
		msg = '''
		<?xml version="1.0" encoding="UTF-8"?>
		<stuResponseMsg xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://cody.glpconnect.com/XSD/StuResponse_Rev1_0.xsd" deliveryTimeStamp="{delivery_timestamp}" messageID="{message_id}" correlationID="{message_id}">
			<state>{state}</state>
			<stateMessage>{message}</stateMessage>
		</stuResponseMsg>
		'''

		msg = msg.gsub('{state}', state)
		msg = msg.gsub('{message}', message)
		msg = msg.gsub('{message_id}', "#{message_id}")
		msg = msg.gsub('{delivery_timestamp}', Time.now.strftime('%d/%m/%Y %H:%M:%S ') + Time.now.zone)

		# no line feeds
		msg = msg.gsub(/\r/,'')
		msg = msg.gsub(/\n/,'')
		msg = msg.gsub(/\t/,'')

		return msg
	end

	# PRV message
	def prv

		begin
			doc  = Nokogiri::XML(request.raw_post) do |config|
				config.options = Nokogiri::XML::ParseOptions::STRICT
			end
		rescue Exception => e

			msg = PrvMessage.new
			msg.raw = request.raw_post
			msg.status = 'malformed'
			msg.extra = "#{e}"
			msg.save

			return render :text => prvResponse('FAIL', "malformed xml: #{e}", msg.id)
		end

		msg = PrvMessage.new
		msg.raw = doc.to_s
		msg.status = 'ok'
		msg.save

		render :text => prvResponse('PASS', 'PRV Message OK', msg.id)
	end

	def prvResponse(state, message='', message_id)
		msg = '''
		<?xml version="1.0" encoding="utf-8"?>
		<prvResponseMsg xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://cody.glpconnect.com/XSD/ProvisionResponse_Rev1_0.xsd" deliveryTimeStamp="{delivery_timestamp}" messageID="{message_id}" correlationID="{message_id}">
			<state>{state}</state>
			<stateMessage>{message}</stateMessage>
		</prvResponseMsg>
		'''

		msg = msg.gsub('{state}', state)
		msg = msg.gsub('{message}', message)
		msg = msg.gsub('{message_id}', "#{message_id}")
		msg = msg.gsub('{delivery_timestamp}', Time.now.strftime('%d/%m/%Y %H:%M:%S ') + Time.now.zone)

		# no line feeds
		msg = msg.gsub(/\r/,'')
		msg = msg.gsub(/\n/,'')
		msg = msg.gsub(/\t/,'')

		return msg
	end

end
