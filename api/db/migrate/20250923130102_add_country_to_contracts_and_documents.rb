class AddCountryToContractsAndDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :contracts, :country_code, :string, null: false, default: "DE"
    add_index  :contracts, :country_code

    add_column :documents, :country_code, :string # optional at upload time
    add_index  :documents, :country_code
  end
end
