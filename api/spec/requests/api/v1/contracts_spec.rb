require "rails_helper"

RSpec.describe "Contracts API", type: :request do
  let(:user)   { create(:user) }
  let(:person) { create(:person, user: user) }

  before { sign_in user }  # Devise helper; if using JWT in tests, swap to token auth headers instead.

  describe "GET /api/v1/contracts" do
    let!(:mine1) { create(:contract, person: person, contract_type: "mobile",   created_at: 2.days.ago) }
    let!(:mine2) { create(:contract, person: person, contract_type: "insurance", created_at: 1.day.ago) }
    let!(:other_users_contract) do
      other_person = create(:person) # belongs to another user
      create(:contract, person: other_person, contract_type: "gym")
    end

    it "lists only my contracts, newest first, paginated" do
      get "/api/v1/contracts", params: { per_page: 20 }
      expect(response).to have_http_status(:ok)

      ids = json.fetch("data").map { |h| h["id"] }
      expect(ids).to eq([mine2.id, mine1.id]) # desc order

      # Pagy metadata exists
      expect(json["pagy"]).to include("count", "page", "items")
    end

    it "respects per_page cap at 100" do
      get "/api/v1/contracts", params: { per_page: 999 }
      expect(response).to have_http_status(:ok)
      expect(json["pagy"]["items"]).to be <= 100
    end

    it "does not include discarded contracts" do
      mine1.discard
      get "/api/v1/contracts"
      ids = json.fetch("data").map { |h| h["id"] }
      expect(ids).to eq([mine2.id])
    end
  end

  describe "GET /api/v1/contracts/:id" do
    it "shows my contract" do
      c = create(:contract, person: person)
      get "/api/v1/contracts/#{c.id}"
      expect(response).to have_http_status(:ok)
      expect(json.dig("person", "id")).to eq(person.id)
    end

    it "404s for a contract not owned by me" do
      other = create(:contract) # belongs to another user's person
      get "/api/v1/contracts/#{other.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/contracts" do
    let(:valid_params) do
      {
        contract: {
          contract_type: "mobile",
          provider: "Telekom",
          currency: "EUR",
          person_id: person.id
        }
      }
    end

    it "creates a contract for a person I own" do
      expect {
        post "/api/v1/contracts", params: valid_params
      }.to change(Contract, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["contract_type"]).to eq("mobile")
      expect(json["person_id"]).to eq(person.id)
    end

    it "normalizes contract_type" do
      params = valid_params
      params[:contract][:contract_type] = "  Mobile "
      post "/api/v1/contracts", params: params
      expect(response).to have_http_status(:created)
      expect(json["contract_type"]).to eq("mobile")
    end

    it "422s when person_id missing" do
      bad = valid_params
      bad[:contract].delete(:person_id)
      post "/api/v1/contracts", params: bad
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to include("person_id is required")
    end

    it "404s when person_id is not owned by me" do
      other_person = create(:person) # other user's person
      bad = valid_params
      bad[:contract][:person_id] = other_person.id
      post "/api/v1/contracts", params: bad
      expect(response).to have_http_status(:not_found)
    end

    it "422s on invalid contract_type" do
      bad = valid_params
      bad[:contract][:contract_type] = "unknown"
      post "/api/v1/contracts", params: bad
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"].join).to match(/Contract type is not included/)
    end
  end

  describe "PATCH /api/v1/contracts/:id" do
    let!(:contract) { create(:contract, person: person, provider: "Old") }

    it "updates allowed fields" do
      patch "/api/v1/contracts/#{contract.id}", params: {
        contract: { provider: "New", monthly_fee: "19.99" }
      }
      expect(response).to have_http_status(:ok)
      expect(json["provider"]).to eq("New")
      expect(json["monthly_fee"]).to eq("19.99")
    end

    it "can reassign to another person I own" do
      p2 = create(:person, user: user, name: "Spouse", relation: "spouse")
      patch "/api/v1/contracts/#{contract.id}", params: { contract: { person_id: p2.id } }
      expect(response).to have_http_status(:ok)
      expect(Contract.find(contract.id).person_id).to eq(p2.id)
    end

    it "404s if reassigning to a person I don't own" do
      other_person = create(:person) # other user's person
      patch "/api/v1/contracts/#{contract.id}", params: { contract: { person_id: other_person.id } }
      expect(response).to have_http_status(:not_found)
    end

    it "422s on invalid contract_type" do
      patch "/api/v1/contracts/#{contract.id}", params: { contract: { contract_type: "bogus" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"].join).to match(/Contract type is not included/)
    end
  end

  describe "DELETE /api/v1/contracts/:id" do
    it "soft-deletes (discard) the contract" do
      c = create(:contract, person: person)
      delete "/api/v1/contracts/#{c.id}"
      expect(response).to have_http_status(:no_content)
      expect(Contract.kept).not_to include(c)
      expect(Contract.with_discarded.find(c.id).discarded_at).to be_present
    end
  end
end
