class CreateSettingsTable < ActiveRecord::Migration[4.2]

  # Commented out for single-database setup (Phase 6 consolidation)
  # def connection
  #   Setting.connection
  # end

  def change
    create_table :settings do |t|
      t.string :key
      t.string :value

      t.timestamps null: false
    end
    add_index :settings, :key
  end
end
