class AddCreatedByToGeofences < ActiveRecord::Migration[4.2]
  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #   Geofence.connection
  # end

  def change
    add_column :geofences, :created_by, :integer
    add_index :geofences, :created_by
  end
end
