class FenceAlert < ActiveRecord::Base
  belongs_to :geofence
  belongs_to :fence_state
end
