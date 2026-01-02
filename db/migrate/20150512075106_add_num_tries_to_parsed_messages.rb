class AddNumTriesToParsedMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :parsed_messages, :num_tries, :integer, :default => 0
  end
end
