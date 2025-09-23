FactoryBot.define do
  factory :contract do
    association :person
    contract_type { "mobile" }
    provider { "Telekom" }
    currency { "EUR" }
    # other attrs are nil by default
  end
end
