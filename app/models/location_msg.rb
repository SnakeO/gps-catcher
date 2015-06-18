class LocationMsg < ActiveRecord::Base
	establish_connection :pg

   has_many :fence_state
end
