class CreateGeofences < ActiveRecord::Migration

   def connection
     GeoFence.connection
   end

  def change
    create_table :geofences do |t|
      t.string :esn
      t.st_polygon :fence, geographic: true
      t.text :meta
      t.boolean :is_single_alert
      t.integer :num_alerts_sent, default: 0
      t.string :alert_type # enter (i), exit (o), both (b)
      t.column :deleted_at, 'timestamp with time zone'

      t.timestamps null: false
    end
    add_index :geofences, :esn
    add_index :geofences, :fence, using: :gist
    add_index :geofences, :is_single_alert
    add_index :geofences, :num_alerts_sent
    add_index :geofences, :deleted_at
  end
end
