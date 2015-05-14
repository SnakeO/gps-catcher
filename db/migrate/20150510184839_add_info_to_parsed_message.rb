class AddInfoToParsedMessage < ActiveRecord::Migration
  def change
    add_column :parsed_messages, :info, :string
  end
end
