module Smart
	module Bdgps
		class Message < ActiveRecord::Base
			self.table_name = "smart_bdgps_messages"
		end
	end
end
