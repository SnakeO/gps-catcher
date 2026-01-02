class CreateFenceState < ActiveRecord::Migration[4.2]
  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #   FenceState.connection
  # end

  def change
    create_table :fence_states do |t|
      t.references :geofence, index: true, foreign_key: true
      t.references :location_msg, index: true, foreign_key: true
      t.string :state
      t.timestamps null: false
    end
  end
end
