# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

ActiveRecord::Base.transaction do
  # Log a message to the console
  puts 'Seeding the database with initial data...'
  u = User.create!(email: "demo@example.com", password: "password123")
  p1 = u.person.create!(name: "Self", dob: Date.new(1998,1,1), relation: "self")
  p1.contracts.create!(type: "Mobile", provider: "Telekom", currency: "EUR", person: p1)
  puts 'Seeding completed.'
end