class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts do |t|
      t.string :type
      t.string :provider
      t.string :category
      t.string :plan_name
      t.string :contract_number
      t.string :customer_number
      t.string :msisdn
      t.date :start_date
      t.date :end_date
      t.integer :min_term_months
      t.integer :notice_period_days
      t.decimal :monthly_fee
      t.decimal :promo_monthly_fee
      t.date :promo_end_date
      t.string :currency
      t.string :termination_email
      t.string :termination_address
      t.text :notes
      t.references :user, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :contracts, :discarded_at
  end
end
