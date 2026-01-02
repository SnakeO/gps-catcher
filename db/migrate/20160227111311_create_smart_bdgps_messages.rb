# rails g migration CreateSmartBdgpsMessages raw:text, status:string, extra:text, processed_stage:integer:index
class CreateSmartBdgpsMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :smart_bdgps_messages do |t|
      t.text :raw
      t.string :status
      t.text :extra
      t.integer :processed_stage, default: 0

      t.timestamps null: false
    end
    add_index :smart_bdgps_messages, :processed_stage
  end
end
