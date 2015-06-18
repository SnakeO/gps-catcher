class FenceState < ActiveRecord::Base
   establish_connection :pg
   
   has_one :fence_alert 
   belongs_to :geofence
   belongs_to :location_msg
end
