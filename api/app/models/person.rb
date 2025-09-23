class Person < ApplicationRecord
  include Discard::Model
  belongs_to :user
  has_many :contracts, dependent: :nullify

  validates :name, presence: true
  validates :relation, presence: true
end
