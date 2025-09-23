class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.references :contract, null: false, foreign_key: true
      t.string :title
      t.text :notes

      t.timestamps
    end
  end
end
