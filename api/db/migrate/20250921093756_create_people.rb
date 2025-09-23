class CreatePeople < ActiveRecord::Migration[7.1]
  def change
    create_table :people do |t|
      t.string :name
      t.date :dob
      t.string :relation
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
