class CreatePrvMessages < ActiveRecord::Migration
  def change
    create_table :prv_messages do |t|
      t.text :raw
      t.string :status
      t.string :extra

      t.timestamps null: false
    end
  end
end
