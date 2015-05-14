class AddMessageIdToParsedMessages < ActiveRecord::Migration
  def change
    add_column :parsed_messages, :message_id, :string
  end
end
