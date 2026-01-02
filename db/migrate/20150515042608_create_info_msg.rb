class CreateInfoMsg < ActiveRecord::Migration[4.2]

  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #    InfoMsg.connection
  # end

  def change
    create_table :info_msgs do |t|
      t.string :esn
      t.column :occurred_at, 'timestamp with time zone'
      t.string :source
      t.string :value
      t.json :meta
      t.string :message_id

      t.timestamps null: false
    end
    add_index :info_msgs, :esn
    add_index :info_msgs, :occurred_at
    add_index :info_msgs, :source
    add_index :info_msgs, :value
    add_index :info_msgs, :message_id, unique: true
  end
end
