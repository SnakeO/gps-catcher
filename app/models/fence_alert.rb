class FenceAlert < ActiveRecord::Base
   # Commented out for single-database setup (Phase 6 consolidation)
   # establish_connection :pg
   
   belongs_to :geofence
   belongs_to :fence_state
end
