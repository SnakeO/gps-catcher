class AddCreatedByToGeofences < ActiveRecord::Migration
  def connection
     Geofence.connection
  end
  
  def change
    add_column :geofences, :created_by, :integer
    add_index :geofences, :created_by
  end
end
