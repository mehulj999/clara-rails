# app/models/document.rb
class Document < ApplicationRecord
  belongs_to :contract, optional: true
  belongs_to :uploaded_by, class_name: 'User', optional: true

  has_one_attached :file

  enum status: { pending: 'pending', parsed: 'parsed', failed: 'failed' }

  validates :sha256, presence: true, uniqueness: true
  validates :status, presence: true
end
