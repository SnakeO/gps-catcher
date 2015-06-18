class CreateFenceAlert < ActiveRecord::Migration
  def connection
     FenceAlert.connection
  end

  def change
    create_table :fence_alerts do |t|
      t.references :geofence, index: true, foreign_key: true
      t.references :fence_state, index: true, foreign_key: true
      t.string :webhook_url
      t.integer :num_tries, default: 0
      t.column :sent_at, 'timestamp with time zone'
      t.integer :response_code
      t.text :response
      t.integer :processed_stage, default: 0
      t.text :info

      t.timestamps null: false
    end
    add_index :fence_alerts, :sent_at
    add_index :fence_alerts, :response_code
  end
end
