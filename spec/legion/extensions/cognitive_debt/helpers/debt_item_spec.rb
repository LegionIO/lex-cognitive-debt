# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebt::Helpers::DebtItem do
  subject(:item) do
    described_class.new(
      label:     'decide on caching strategy',
      debt_type: :deferred_decision,
      principal: 0.4,
      domain:    'architecture'
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(item.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the label' do
      expect(item.label).to eq('decide on caching strategy')
    end

    it 'stores the debt_type as a symbol' do
      expect(item.debt_type).to eq(:deferred_decision)
    end

    it 'stores the principal' do
      expect(item.principal).to eq(0.4)
    end

    it 'starts with zero accrued_interest' do
      expect(item.accrued_interest).to eq(0.0)
    end

    it 'stores the domain' do
      expect(item.domain).to eq('architecture')
    end

    it 'sets created_at to current time' do
      expect(item.created_at).to be_a(Time)
    end

    it 'has nil repaid_at initially' do
      expect(item.repaid_at).to be_nil
    end

    it 'clamps negative principal to 0' do
      negative = described_class.new(label: 'x', debt_type: :deferred_decision, principal: -1.0, domain: 'x')
      expect(negative.principal).to eq(0.0)
    end
  end

  describe '#total_cost' do
    it 'equals principal when no interest has accrued' do
      expect(item.total_cost).to eq(0.4)
    end

    it 'includes accrued interest after accrue!' do
      item.accrue!
      expect(item.total_cost).to be_within(1e-10).of(0.4 + (0.05 * 0.4))
    end

    it 'rounds to 10 decimal places' do
      3.times { item.accrue! }
      expect(item.total_cost.to_s).not_to match(/e/)
    end
  end

  describe '#accrue!' do
    it 'increases accrued_interest by INTEREST_RATE * principal' do
      item.accrue!
      expect(item.accrued_interest).to be_within(1e-10).of(0.05 * 0.4)
    end

    it 'compounds over multiple calls' do
      item.accrue!
      item.accrue!
      expected = (0.05 * 0.4) * 2
      expect(item.accrued_interest).to be_within(1e-10).of(expected)
    end

    it 'does nothing when already repaid' do
      item.repay!(amount: item.total_cost + 1.0)
      item.accrue!
      expect(item.accrued_interest).to eq(0.0)
    end
  end

  describe '#repay!' do
    it 'reduces principal by the amount' do
      item.repay!(amount: 0.1)
      expect(item.principal).to be_within(1e-10).of(0.3)
    end

    it 'reduces accrued_interest first when present' do
      item.accrue!
      before_interest = item.accrued_interest
      item.repay!(amount: 0.01)
      expect(item.accrued_interest).to eq([0.0, before_interest - 0.01].max.round(10))
    end

    it 'does not allow principal to go below zero' do
      item.repay!(amount: 99.0)
      expect(item.principal).to eq(0.0)
    end

    it 'marks repaid_at when fully paid off' do
      item.repay!(amount: 10.0)
      expect(item.repaid_at).not_to be_nil
    end

    it 'does nothing when already repaid' do
      item.repay!(amount: 10.0)
      first_repaid_at = item.repaid_at
      item.repay!(amount: 0.1)
      expect(item.repaid_at).to eq(first_repaid_at)
    end
  end

  describe '#repaid?' do
    it 'returns false initially' do
      expect(item.repaid?).to be false
    end

    it 'returns true after full repayment' do
      item.repay!(amount: 10.0)
      expect(item.repaid?).to be true
    end
  end

  describe '#severity_label' do
    it 'returns :negligible for small cost' do
      small = described_class.new(label: 'x', debt_type: :deferred_decision, principal: 0.1, domain: 'x')
      expect(small.severity_label).to eq(:negligible)
    end

    it 'returns :minor for cost around 0.3' do
      minor = described_class.new(label: 'x', debt_type: :deferred_decision, principal: 0.3, domain: 'x')
      expect(minor.severity_label).to eq(:minor)
    end

    it 'returns :moderate for cost around 0.5' do
      moderate = described_class.new(label: 'x', debt_type: :deferred_decision, principal: 0.5, domain: 'x')
      expect(moderate.severity_label).to eq(:moderate)
    end

    it 'returns :severe for cost around 0.7' do
      severe = described_class.new(label: 'x', debt_type: :deferred_decision, principal: 0.7, domain: 'x')
      expect(severe.severity_label).to eq(:severe)
    end

    it 'returns :critical for cost >= 0.8' do
      critical = described_class.new(label: 'x', debt_type: :deferred_decision, principal: 0.9, domain: 'x')
      expect(critical.severity_label).to eq(:critical)
    end
  end

  describe '#age_seconds' do
    it 'returns a float >= 0' do
      expect(item.age_seconds).to be >= 0.0
    end

    it 'increases over time' do
      age1 = item.age_seconds
      sleep(0.01)
      age2 = item.age_seconds
      expect(age2).to be >= age1
    end

    it 'uses repaid_at as reference when repaid' do
      item.repay!(amount: 10.0)
      age = item.age_seconds
      sleep(0.01)
      expect(item.age_seconds).to eq(age)
    end
  end

  describe '#to_h' do
    let(:hash) { item.to_h }

    it 'includes id' do
      expect(hash[:id]).to eq(item.id)
    end

    it 'includes label' do
      expect(hash[:label]).to eq(item.label)
    end

    it 'includes debt_type' do
      expect(hash[:debt_type]).to eq(:deferred_decision)
    end

    it 'includes principal' do
      expect(hash[:principal]).to eq(0.4)
    end

    it 'includes accrued_interest' do
      expect(hash[:accrued_interest]).to eq(0.0)
    end

    it 'includes total_cost' do
      expect(hash[:total_cost]).to eq(0.4)
    end

    it 'includes domain' do
      expect(hash[:domain]).to eq('architecture')
    end

    it 'includes severity' do
      expect(hash[:severity]).to be_a(Symbol)
    end

    it 'includes age_seconds' do
      expect(hash[:age_seconds]).to be_a(Float)
    end

    it 'includes created_at as ISO8601 string' do
      expect(hash[:created_at]).to be_a(String)
    end

    it 'includes repaid_at as nil initially' do
      expect(hash[:repaid_at]).to be_nil
    end

    it 'includes repaid: false initially' do
      expect(hash[:repaid]).to be false
    end

    it 'includes repaid: true after repayment' do
      item.repay!(amount: 10.0)
      expect(item.to_h[:repaid]).to be true
    end
  end
end
