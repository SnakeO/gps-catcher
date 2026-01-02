class CreateStuMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :stu_messages do |t|
      t.text :raw
      t.string :status
      t.string :extra

      t.timestamps null: false
    end
  end
end
