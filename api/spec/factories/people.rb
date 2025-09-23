
FactoryBot.define do
  factory :person do
    association :user
    name { "Self" }
    relation { "self" }
    dob { Date.new(1995,1,1) }
  end
end
