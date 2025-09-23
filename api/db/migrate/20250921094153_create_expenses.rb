class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :contract, null: false, foreign_key: true
      t.string :name
      t.string :expense_type
      t.decimal :amount
      t.string :currency

      t.timestamps
    end
  end
end
