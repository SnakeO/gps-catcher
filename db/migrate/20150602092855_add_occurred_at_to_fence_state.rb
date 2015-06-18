class AddOccurredAtToFenceState < ActiveRecord::Migration
   def connection
     FenceState.connection
  end
  
  def change
    add_column :fence_states, :occurred_at, 'timestamp with time zone'
    add_index :fence_states, :occurred_at
  end
end
