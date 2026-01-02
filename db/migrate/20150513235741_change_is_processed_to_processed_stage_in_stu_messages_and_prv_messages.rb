class ChangeIsProcessedToProcessedStageInStuMessagesAndPrvMessages < ActiveRecord::Migration[4.2]
  def change
    # PostgreSQL requires dropping default, converting type, then setting new default
    rename_column :stu_messages, :is_processed, :processed_stage
    execute "ALTER TABLE stu_messages ALTER COLUMN processed_stage DROP DEFAULT"
    execute "ALTER TABLE stu_messages ALTER COLUMN processed_stage TYPE integer USING CASE WHEN processed_stage THEN 1 ELSE 0 END"
    execute "ALTER TABLE stu_messages ALTER COLUMN processed_stage SET DEFAULT 0"

    rename_column :prv_messages, :is_processed, :processed_stage
    execute "ALTER TABLE prv_messages ALTER COLUMN processed_stage DROP DEFAULT"
    execute "ALTER TABLE prv_messages ALTER COLUMN processed_stage TYPE integer USING CASE WHEN processed_stage THEN 1 ELSE 0 END"
    execute "ALTER TABLE prv_messages ALTER COLUMN processed_stage SET DEFAULT 0"
  end
end
