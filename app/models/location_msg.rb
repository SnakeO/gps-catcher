class LocationMsg < ActiveRecord::Base
	# Commented out for single-database setup (Phase 6 consolidation)
	# establish_connection :pg

   has_many :fence_state
end
