class AddEsnToFenceState < ActiveRecord::Migration[4.2]
  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #   FenceState.connection
  # end

  def change
    add_column :fence_states, :esn, :string
    add_index :fence_states, :esn
  end
end
