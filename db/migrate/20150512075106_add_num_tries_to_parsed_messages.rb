class AddNumTriesToParsedMessages < ActiveRecord::Migration
  def change
    add_column :parsed_messages, :num_tries, :integer, :default => 0
  end
end
