class CreateReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :reminders do |t|
      t.references :contract, null: false, foreign_key: true
      t.string :title
      t.text :notes
      t.datetime :due_at
      t.integer :status

      t.timestamps
    end
  end
end
