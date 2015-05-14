class AddIsProcessedToPrvMessages < ActiveRecord::Migration
  def change
    add_column :prv_messages, :is_processed, :boolean, :default => false
  end
end
