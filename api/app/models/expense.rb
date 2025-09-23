class Expense < ApplicationRecord
  include Discard::Model
  belongs_to :contract
  validates :name, :expense_type, :amount, :currency, presence: true
end
