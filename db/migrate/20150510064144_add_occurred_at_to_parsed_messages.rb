class AddOccurredAtToParsedMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :parsed_messages, :occurred_at, :datetime
  end
end
