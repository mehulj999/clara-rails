require "rails_helper"

RSpec.describe Contract, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:person) }
    it { is_expected.to have_many(:reminders).dependent(:destroy) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
    it { is_expected.to have_many(:expenses).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:contract) }

    it { is_expected.to validate_presence_of(:contract_type) }
    it { is_expected.to validate_inclusion_of(:contract_type).in_array(%w[mobile gym insurance]) }
    it { is_expected.to validate_presence_of(:currency) }
  end

  describe "normalization" do
    it "downcases and strips contract_type" do
      c = build(:contract, contract_type: "  Mobile ")
      expect(c).to be_valid
      expect(c.contract_type).to eq("mobile")
    end
  end

  describe "scopes" do
    let!(:mobile)    { create(:contract, contract_type: "mobile") }
    let!(:gym)       { create(:contract, contract_type: "gym") }
    let!(:insurance) { create(:contract, contract_type: "insurance") }
    let!(:discarded) { create(:contract, contract_type: "mobile").tap(&:discard) }

    it ".kept returns only non-discarded" do
      expect(Contract.kept).to contain_exactly(mobile, gym, insurance)
    end

    it ".by_type filters by normalized value" do
      expect(Contract.by_type("Mobile")).to contain_exactly(mobile)
      expect(Contract.by_type(:insurance)).to contain_exactly(insurance)
    end

    it ".mobile/.gym/.insurance helpers work" do
      expect(Contract.mobile).to     contain_exactly(mobile)
      expect(Contract.gym).to        contain_exactly(gym)
      expect(Contract.insurance).to  contain_exactly(insurance)
    end
  end

  describe "soft delete (discard)" do
    it "marks discarded_at and excludes from kept" do
      c = create(:contract)
      expect { c.discard }.to change { c.discarded_at.present? }.from(false).to(true)
      expect(Contract.kept).not_to include(c)
    end
  end
end
