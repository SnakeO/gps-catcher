class ChangeParsedMessagesInfo < ActiveRecord::Migration
  def change
      change_table :parsed_messages do |t|
         t.change :info, :text
      end
  end
end
