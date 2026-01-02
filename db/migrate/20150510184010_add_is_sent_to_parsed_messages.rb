class AddIsSentToParsedMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :parsed_messages, :is_sent, :boolean, :default => false
  end
end
