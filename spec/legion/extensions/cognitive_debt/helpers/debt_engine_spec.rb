# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebt::Helpers::DebtEngine do
  subject(:engine) { described_class.new }

  let(:valid_type) { :deferred_decision }
  let(:label)      { 'choose database index strategy' }

  def create_sample(label: 'sample debt', debt_type: valid_type, principal: 0.3, domain: 'general')
    engine.create_debt(label: label, debt_type: debt_type, principal: principal, domain: domain)
  end

  describe '#create_debt' do
    it 'returns created: true for valid debt_type' do
      result = create_sample
      expect(result[:created]).to be true
    end

    it 'returns a debt_id' do
      result = create_sample
      expect(result[:debt_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'includes debt hash in result' do
      result = create_sample
      expect(result[:debt]).to be_a(Hash)
      expect(result[:debt][:label]).to eq('sample debt')
    end

    it 'returns created: false for invalid debt_type' do
      result = engine.create_debt(label: label, debt_type: :invalid_type, principal: 0.3, domain: 'x')
      expect(result[:created]).to be false
      expect(result[:reason]).to eq(:debt_type_invalid)
    end

    it 'accepts all five valid debt types' do
      Legion::Extensions::CognitiveDebt::Helpers::Constants::DEBT_TYPES.each do |type|
        result = engine.create_debt(label: "debt #{type}", debt_type: type, principal: 0.1, domain: 'x')
        expect(result[:created]).to be true
      end
    end

    it 'enforces MAX_DEBTS limit' do
      stub_const('Legion::Extensions::CognitiveDebt::Helpers::Constants::MAX_DEBTS', 2)
      create_sample(label: 'first')
      create_sample(label: 'second')
      result = create_sample(label: 'third')
      expect(result[:created]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end

    it 'uses DEFAULT_PRINCIPAL when principal is omitted' do
      result = engine.create_debt(label: label, debt_type: valid_type, domain: 'x')
      expect(result[:debt][:principal]).to eq(Legion::Extensions::CognitiveDebt::Helpers::Constants::DEFAULT_PRINCIPAL)
    end
  end

  describe '#repay_debt' do
    let!(:debt_id) { create_sample[:debt_id] }

    it 'returns found: true for existing debt' do
      result = engine.repay_debt(debt_id: debt_id)
      expect(result[:found]).to be true
    end

    it 'returns repaid: true after repayment' do
      result = engine.repay_debt(debt_id: debt_id)
      expect(result[:repaid]).to be true
    end

    it 'returns found: false for nonexistent debt_id' do
      result = engine.repay_debt(debt_id: 'nonexistent-id')
      expect(result[:found]).to be false
    end

    it 'returns reason: :already_repaid if already repaid' do
      engine.repay_debt(debt_id: debt_id, amount: 99.0)
      result = engine.repay_debt(debt_id: debt_id)
      expect(result[:reason]).to eq(:already_repaid)
    end

    it 'includes debt hash in result' do
      result = engine.repay_debt(debt_id: debt_id)
      expect(result[:debt]).to be_a(Hash)
    end
  end

  describe '#accrue_all_interest' do
    it 'accrues interest on all active debts' do
      create_sample(principal: 0.4)
      create_sample(principal: 0.6)
      result = engine.accrue_all_interest
      expect(result[:accrued]).to eq(2)
    end

    it 'skips repaid debts' do
      id = create_sample[:debt_id]
      engine.repay_debt(debt_id: id, amount: 99.0)
      result = engine.accrue_all_interest
      expect(result[:accrued]).to eq(0)
    end

    it 'returns total_debt' do
      create_sample(principal: 0.5)
      result = engine.accrue_all_interest
      expect(result[:total_debt]).to be > 0.0
    end
  end

  describe '#total_debt' do
    it 'returns 0 for empty engine' do
      expect(engine.total_debt).to eq(0.0)
    end

    it 'sums active debt total_cost values' do
      create_sample(principal: 0.3)
      create_sample(principal: 0.4)
      expect(engine.total_debt).to be_within(1e-10).of(0.7)
    end

    it 'excludes repaid debts' do
      id = create_sample(principal: 0.3)[:debt_id]
      engine.repay_debt(debt_id: id, amount: 99.0)
      create_sample(principal: 0.2)
      expect(engine.total_debt).to be_within(1e-10).of(0.2)
    end
  end

  describe '#debt_by_type' do
    before do
      create_sample(debt_type: :deferred_decision, principal: 0.3)
      create_sample(debt_type: :deferred_decision, principal: 0.2)
      create_sample(debt_type: :unprocessed_input, principal: 0.1)
    end

    it 'returns matching debts for the type' do
      result = engine.debt_by_type(debt_type: :deferred_decision)
      expect(result[:count]).to eq(2)
    end

    it 'returns zero for types with no debts' do
      result = engine.debt_by_type(debt_type: :unresolved_conflict)
      expect(result[:count]).to eq(0)
    end

    it 'includes items array' do
      result = engine.debt_by_type(debt_type: :deferred_decision)
      expect(result[:items]).to be_an(Array)
    end
  end

  describe '#debt_by_domain' do
    before do
      create_sample(domain: 'architecture', principal: 0.3)
      create_sample(domain: 'architecture', principal: 0.2)
      create_sample(domain: 'security', principal: 0.4)
    end

    it 'returns debts in the specified domain' do
      result = engine.debt_by_domain(domain: 'architecture')
      expect(result[:count]).to eq(2)
    end

    it 'returns zero for unknown domain' do
      result = engine.debt_by_domain(domain: 'unknown')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#most_costly' do
    before do
      create_sample(label: 'cheap', principal: 0.1)
      create_sample(label: 'medium', principal: 0.5)
      create_sample(label: 'expensive', principal: 0.9)
    end

    it 'returns debts sorted by total_cost descending' do
      result = engine.most_costly(limit: 3)
      costs = result[:items].map { |d| d[:total_cost] }
      expect(costs).to eq(costs.sort.reverse)
    end

    it 'respects the limit' do
      result = engine.most_costly(limit: 2)
      expect(result[:count]).to eq(2)
    end

    it 'returns the most expensive first' do
      result = engine.most_costly(limit: 1)
      expect(result[:items].first[:label]).to eq('expensive')
    end
  end

  describe '#oldest_debts' do
    it 'returns debts sorted by created_at ascending' do
      create_sample(label: 'first')
      sleep(0.01)
      create_sample(label: 'second')
      result = engine.oldest_debts(limit: 2)
      times = result[:items].map { |d| d[:created_at] }
      expect(times).to eq(times.sort)
    end

    it 'respects the limit' do
      3.times { |i| create_sample(label: "debt #{i}") }
      result = engine.oldest_debts(limit: 2)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#debt_report' do
    before do
      create_sample(debt_type: :deferred_decision, principal: 0.3)
      create_sample(debt_type: :unprocessed_input, principal: 0.5)
    end

    it 'includes total_debt' do
      report = engine.debt_report
      expect(report[:total_debt]).to be > 0.0
    end

    it 'includes active_count' do
      report = engine.debt_report
      expect(report[:active_count]).to eq(2)
    end

    it 'includes repaid_count' do
      report = engine.debt_report
      expect(report[:repaid_count]).to eq(0)
    end

    it 'includes by_type breakdown for all five types' do
      report = engine.debt_report
      expect(report[:by_type].keys).to match_array(
        Legion::Extensions::CognitiveDebt::Helpers::Constants::DEBT_TYPES
      )
    end

    it 'includes recommended_priority' do
      report = engine.debt_report
      expect(report[:recommended_priority]).to be_an(Array)
    end

    it 'prioritizes highest cost debt first' do
      report = engine.debt_report
      costs = report[:recommended_priority].map { |d| d[:total_cost] }
      expect(costs).to eq(costs.sort.reverse)
    end
  end

  describe '#prune_repaid' do
    it 'removes repaid debts' do
      id = create_sample[:debt_id]
      engine.repay_debt(debt_id: id, amount: 99.0)
      result = engine.prune_repaid
      expect(result[:pruned]).to eq(1)
    end

    it 'does not remove active debts' do
      create_sample
      result = engine.prune_repaid
      expect(result[:remaining]).to eq(1)
    end

    it 'returns pruned count and remaining count' do
      id = create_sample[:debt_id]
      engine.repay_debt(debt_id: id, amount: 99.0)
      create_sample
      result = engine.prune_repaid
      expect(result[:pruned]).to eq(1)
      expect(result[:remaining]).to eq(1)
    end
  end

  describe '#to_h' do
    before { create_sample(principal: 0.4) }

    let(:hash) { engine.to_h }

    it 'includes total_debt' do
      expect(hash[:total_debt]).to be_within(1e-10).of(0.4)
    end

    it 'includes active_count' do
      expect(hash[:active_count]).to eq(1)
    end

    it 'includes total_count' do
      expect(hash[:total_count]).to eq(1)
    end

    it 'includes debts array' do
      expect(hash[:debts]).to be_an(Array)
      expect(hash[:debts].size).to eq(1)
    end
  end
end
