class AddOccurredAtToParsedMessages < ActiveRecord::Migration
  def change
    add_column :parsed_messages, :occurred_at, :datetime
  end
end
