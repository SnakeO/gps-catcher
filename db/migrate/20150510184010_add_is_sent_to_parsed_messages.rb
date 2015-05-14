class AddIsSentToParsedMessages < ActiveRecord::Migration
  def change
    add_column :parsed_messages, :is_sent, :boolean, :default => false
  end
end
