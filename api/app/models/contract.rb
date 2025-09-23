# app/models/contract.rb
class Contract < ApplicationRecord
  include Discard::Model

  belongs_to :person

  ALLOWED_TYPES = %w[mobile gym insurance internet].freeze
  ALLOWED_COUNTRIES = %w[DE IN].freeze

  has_many :reminders, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :expenses,  dependent: :destroy

  before_validation :normalize_contract_type!
  before_validation :normalize_country!
  before_validation :default_currency_from_country!

  validates :contract_type, presence: true, inclusion: { in: ALLOWED_TYPES }
  validates :currency, presence: true
  validates :country_code,  presence: true, inclusion: { in: ALLOWED_COUNTRIES }
  validates :currency,      presence: true

  scope :kept, -> { where(discarded_at: nil) }
  scope :by_type,   ->(t) { where(contract_type: t.to_s.downcase) }
  scope :mobile,    -> { where(contract_type: 'mobile') }
  scope :gym,       -> { where(contract_type: 'gym') }
  scope :insurance, -> { where(contract_type: 'insurance') }
  scope :internet,  -> { where(contract_type: 'internet') }
  scope :indian,  -> { where(country_code: 'IN') }
  scope :german,  -> { where(country_code: 'DE') }

  private

  def normalize_contract_type!
    self.contract_type = contract_type.to_s.downcase.strip if contract_type.present?
  end

  def normalize_country!
    c = country_code.to_s.upcase.strip
    self.country_code = ALLOWED_COUNTRIES.include?(c) ? c : 'DE'
  end

  def default_currency_from_country!
    self.currency ||= (country_code == 'IN' ? 'INR' : 'EUR')
  end
end
