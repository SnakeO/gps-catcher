class ChangeIsProcessedToProcessedStageInStuMessagesAndPrvMessages < ActiveRecord::Migration
  def change
      change_table :stu_messages do |t|
         t.rename :is_processed, :processed_stage
         t.change :processed_stage, :integer, :default => 0
      end

      change_table :prv_messages do |t|
         t.rename :is_processed, :processed_stage
         t.change :processed_stage, :integer, :default => 0
      end
  end
end
