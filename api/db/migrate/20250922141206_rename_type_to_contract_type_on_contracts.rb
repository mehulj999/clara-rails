# db/migrate/20250922131000_rename_type_to_contract_type_on_contracts.rb
class RenameTypeToContractTypeOnContracts < ActiveRecord::Migration[7.1]
  ALLOWED = %w[mobile gym insurance].freeze

  def up
    # 1) Rename column
    rename_column :contracts, :type, :contract_type

    # 2) Normalize existing values to lowercase/trim (in case data exists)
    execute <<~SQL
      UPDATE contracts
      SET contract_type = LOWER(TRIM(contract_type))
      WHERE contract_type IS NOT NULL;
    SQL

    # 3) Add index for common filtering
    add_index :contracts, :contract_type

    # 4) Optional: add a DB check constraint (keeps DB consistent)
    add_check_constraint :contracts,
      "contract_type IN ('mobile','gym','insurance')",
      name: "contracts_contract_type_check"
  end

  def down
    # Drop constraint and index then rename back
    remove_check_constraint :contracts, name: "contracts_contract_type_check"
    remove_index :contracts, :contract_type
    rename_column :contracts, :contract_type, :type
  end
end
