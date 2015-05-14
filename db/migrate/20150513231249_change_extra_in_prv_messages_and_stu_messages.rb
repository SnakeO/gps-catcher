class ChangeExtraInPrvMessagesAndStuMessages < ActiveRecord::Migration
  def change
      change_table :stu_messages do |t|
         t.change :extra, :text
      end

      change_table :prv_messages do |t|
         t.change :extra, :text
      end
  end
end
