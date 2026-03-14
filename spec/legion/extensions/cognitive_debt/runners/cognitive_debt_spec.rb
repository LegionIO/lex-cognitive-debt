# frozen_string_literal: true

require 'legion/extensions/cognitive_debt/client'

RSpec.describe Legion::Extensions::CognitiveDebt::Runners::CognitiveDebt do
  let(:engine) { Legion::Extensions::CognitiveDebt::Helpers::DebtEngine.new }
  let(:client) { Legion::Extensions::CognitiveDebt::Client.new(engine: engine) }

  describe '#create_debt' do
    it 'creates a debt via the engine' do
      result = client.create_debt(label: 'decide on auth', debt_type: :deferred_decision)
      expect(result[:created]).to be true
    end

    it 'returns a debt_id' do
      result = client.create_debt(label: 'decide on auth', debt_type: :deferred_decision)
      expect(result[:debt_id]).not_to be_nil
    end

    it 'passes custom principal' do
      result = client.create_debt(label: 'x', debt_type: :unprocessed_input, principal: 0.7)
      expect(result[:debt][:principal]).to eq(0.7)
    end

    it 'passes custom domain' do
      result = client.create_debt(label: 'x', debt_type: :incomplete_analysis, domain: 'security')
      expect(result[:debt][:domain]).to eq('security')
    end

    it 'uses default principal when not specified' do
      result = client.create_debt(label: 'x', debt_type: :deferred_decision)
      expected = Legion::Extensions::CognitiveDebt::Helpers::Constants::DEFAULT_PRINCIPAL
      expect(result[:debt][:principal]).to eq(expected)
    end

    it 'returns created: false for invalid type' do
      result = client.create_debt(label: 'x', debt_type: :nonexistent)
      expect(result[:created]).to be false
    end
  end

  describe '#repay_debt' do
    let!(:debt_id) do
      client.create_debt(label: 'unresolved thing', debt_type: :unresolved_conflict)[:debt_id]
    end

    it 'repays an existing debt' do
      result = client.repay_debt(debt_id: debt_id)
      expect(result[:repaid]).to be true
    end

    it 'returns found: false for unknown id' do
      result = client.repay_debt(debt_id: 'no-such-id')
      expect(result[:found]).to be false
    end

    it 'uses custom amount' do
      result = client.repay_debt(debt_id: debt_id, amount: 0.05)
      expect(result[:found]).to be true
    end
  end

  describe '#accrue_interest' do
    before { client.create_debt(label: 'pending work', debt_type: :pending_integration, principal: 0.4) }

    it 'accrues interest on active debts' do
      result = client.accrue_interest
      expect(result[:accrued]).to eq(1)
    end

    it 'returns total_debt' do
      result = client.accrue_interest
      expect(result[:total_debt]).to be > 0.4
    end
  end

  describe '#total_debt' do
    it 'returns 0 for empty engine' do
      result = client.total_debt
      expect(result[:total_debt]).to eq(0.0)
    end

    it 'reflects created debts' do
      client.create_debt(label: 'x', debt_type: :deferred_decision, principal: 0.5)
      result = client.total_debt
      expect(result[:total_debt]).to be_within(1e-10).of(0.5)
    end
  end

  describe '#debt_by_type' do
    before do
      client.create_debt(label: 'a', debt_type: :deferred_decision)
      client.create_debt(label: 'b', debt_type: :deferred_decision)
      client.create_debt(label: 'c', debt_type: :unprocessed_input)
    end

    it 'returns count for the specified type' do
      result = client.debt_by_type(debt_type: :deferred_decision)
      expect(result[:count]).to eq(2)
    end

    it 'returns 0 for type with no debts' do
      result = client.debt_by_type(debt_type: :unresolved_conflict)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#debt_by_domain' do
    before do
      client.create_debt(label: 'a', debt_type: :deferred_decision, domain: 'perf')
      client.create_debt(label: 'b', debt_type: :unprocessed_input, domain: 'perf')
    end

    it 'returns count for the specified domain' do
      result = client.debt_by_domain(domain: 'perf')
      expect(result[:count]).to eq(2)
    end

    it 'returns 0 for unknown domain' do
      result = client.debt_by_domain(domain: 'unknown')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#most_costly' do
    before do
      client.create_debt(label: 'cheap', debt_type: :deferred_decision, principal: 0.1)
      client.create_debt(label: 'expensive', debt_type: :deferred_decision, principal: 0.9)
    end

    it 'returns most costly first' do
      result = client.most_costly(limit: 2)
      expect(result[:items].first[:principal]).to eq(0.9)
    end

    it 'respects the limit' do
      result = client.most_costly(limit: 1)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#oldest_debts' do
    it 'returns debts ordered by age' do
      client.create_debt(label: 'old', debt_type: :deferred_decision)
      sleep(0.01)
      client.create_debt(label: 'newer', debt_type: :deferred_decision)
      result = client.oldest_debts(limit: 2)
      expect(result[:items].first[:label]).to eq('old')
    end
  end

  describe '#debt_report' do
    before do
      client.create_debt(label: 'decision', debt_type: :deferred_decision, principal: 0.3)
      client.create_debt(label: 'analysis', debt_type: :incomplete_analysis, principal: 0.6)
    end

    it 'includes total_debt' do
      report = client.debt_report
      expect(report[:total_debt]).to be > 0.0
    end

    it 'includes active_count' do
      report = client.debt_report
      expect(report[:active_count]).to eq(2)
    end

    it 'includes by_type with all five types' do
      report = client.debt_report
      expect(report[:by_type].keys).to match_array(
        Legion::Extensions::CognitiveDebt::Helpers::Constants::DEBT_TYPES
      )
    end

    it 'includes recommended_priority' do
      report = client.debt_report
      expect(report[:recommended_priority]).not_to be_empty
    end
  end

  describe '#prune_repaid' do
    it 'prunes repaid debts and returns counts' do
      id = client.create_debt(label: 'done', debt_type: :deferred_decision)[:debt_id]
      client.repay_debt(debt_id: id, amount: 99.0)
      result = client.prune_repaid
      expect(result[:pruned]).to eq(1)
      expect(result[:remaining]).to eq(0)
    end

    it 'returns pruned: 0 when nothing to prune' do
      client.create_debt(label: 'active', debt_type: :deferred_decision)
      result = client.prune_repaid
      expect(result[:pruned]).to eq(0)
    end
  end
end
