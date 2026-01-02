class AddMessageIdToParsedMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :parsed_messages, :message_id, :string
  end
end
