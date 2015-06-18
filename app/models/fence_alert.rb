class FenceAlert < ActiveRecord::Base
   establish_connection :pg
   
   belongs_to :geofence
   belongs_to :fence_state
end
