class ChangeParsedMessagesInfo < ActiveRecord::Migration[4.2]
  def change
      change_table :parsed_messages do |t|
         t.change :info, :text
      end
  end
end
