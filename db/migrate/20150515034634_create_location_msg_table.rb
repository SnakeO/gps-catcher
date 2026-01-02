class CreateLocationMsgTable < ActiveRecord::Migration[4.2]

  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #    LocationMsg.connection
  # end

  def change
    create_table :location_msgs do |t|
      t.string :esn
      t.column :occurred_at, 'timestamp with time zone'
      t.st_point :point, geographic: true
      t.json :meta
      t.string :message_id

      t.timestamps null: false
    end
    add_index :location_msgs, :esn
    add_index :location_msgs, :occurred_at
    add_index :location_msgs, :message_id, unique: true
    add_index :location_msgs, :point, using: :gist
  end
end
