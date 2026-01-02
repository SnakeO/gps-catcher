class AddInfoToParsedMessage < ActiveRecord::Migration[4.2]
  def change
    add_column :parsed_messages, :info, :string
  end
end
