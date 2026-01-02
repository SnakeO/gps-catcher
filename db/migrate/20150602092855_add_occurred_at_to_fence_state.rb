class AddOccurredAtToFenceState < ActiveRecord::Migration[4.2]
  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #   FenceState.connection
  # end

  def change
    add_column :fence_states, :occurred_at, 'timestamp with time zone'
    add_index :fence_states, :occurred_at
  end
end
