class AddIsProcessedToPrvMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :prv_messages, :is_processed, :boolean, :default => false
  end
end
