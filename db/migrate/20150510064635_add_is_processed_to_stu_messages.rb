class AddIsProcessedToStuMessages < ActiveRecord::Migration
  def change
    add_column :stu_messages, :is_processed, :boolean, :default => false
  end
end
