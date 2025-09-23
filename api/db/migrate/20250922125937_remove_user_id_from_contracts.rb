class RemoveUserIdFromContracts < ActiveRecord::Migration[7.1]
  def change
    remove_column :contracts, :user_id, :integer
  end
end
