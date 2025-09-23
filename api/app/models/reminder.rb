class Reminder < ApplicationRecord
  include Discard::Model
  belongs_to :contract

  enum status: { pending: 0, done: 1 }, _default: :pending
  validates :title, presence: true
  validates :due_at, presence: true
end
