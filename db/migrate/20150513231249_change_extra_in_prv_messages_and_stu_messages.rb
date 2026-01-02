class ChangeExtraInPrvMessagesAndStuMessages < ActiveRecord::Migration[4.2]
  def change
      change_table :stu_messages do |t|
         t.change :extra, :text
      end

      change_table :prv_messages do |t|
         t.change :extra, :text
      end
  end
end
