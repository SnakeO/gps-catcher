class CreateParsedMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :parsed_messages do |t|

      t.string :origin_message_type
      t.integer :origin_message_id
      t.string :esn
      t.string :source
      t.string :value
      t.string :meta

      t.timestamps null: false
    end
  end
end
