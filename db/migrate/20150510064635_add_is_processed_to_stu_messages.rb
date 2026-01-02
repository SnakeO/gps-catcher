class AddIsProcessedToStuMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :stu_messages, :is_processed, :boolean, :default => false
  end
end
