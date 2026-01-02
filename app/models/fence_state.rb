class FenceState < ActiveRecord::Base
   # Commented out for single-database setup (Phase 6 consolidation)
   # establish_connection :pg
   
   has_one :fence_alert 
   belongs_to :geofence
   belongs_to :location_msg
end
