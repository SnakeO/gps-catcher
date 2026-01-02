class CreateGps306aMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :gps306a_messages do |t|
      t.text :raw
      t.string :status
      t.text :extra
      t.integer :processed_stage, default: 0

      t.timestamps null: false
    end
    add_index :gps306a_messages, :processed_stage
  end
end
