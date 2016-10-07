# rails g migration CreateXexunTk1022Messages raw:text, status:string, extra:text, processed_stage:integer:index
class CreateXexunTk1022Messages < ActiveRecord::Migration
  def change
    create_table :xexun_tk1022_messages do |t|
      t.text :raw
      t.string :status
      t.text :extra
      t.integer :processed_stage, default: 0

      t.timestamps null: false
    end
    add_index :xexun_tk1022_messages, :processed_stage
  end
end
