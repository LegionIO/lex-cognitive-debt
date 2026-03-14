# frozen_string_literal: true

require 'legion/extensions/cognitive_debt/client'

RSpec.describe Legion::Extensions::CognitiveDebt::Client do
  let(:client) { described_class.new }

  it 'responds to create_debt' do
    expect(client).to respond_to(:create_debt)
  end

  it 'responds to repay_debt' do
    expect(client).to respond_to(:repay_debt)
  end

  it 'responds to accrue_interest' do
    expect(client).to respond_to(:accrue_interest)
  end

  it 'responds to total_debt' do
    expect(client).to respond_to(:total_debt)
  end

  it 'responds to debt_by_type' do
    expect(client).to respond_to(:debt_by_type)
  end

  it 'responds to debt_by_domain' do
    expect(client).to respond_to(:debt_by_domain)
  end

  it 'responds to most_costly' do
    expect(client).to respond_to(:most_costly)
  end

  it 'responds to oldest_debts' do
    expect(client).to respond_to(:oldest_debts)
  end

  it 'responds to debt_report' do
    expect(client).to respond_to(:debt_report)
  end

  it 'responds to prune_repaid' do
    expect(client).to respond_to(:prune_repaid)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::CognitiveDebt::Helpers::DebtEngine.new
    c = described_class.new(engine: engine)
    c.create_debt(label: 'test', debt_type: :deferred_decision, principal: 0.3)
    expect(engine.total_debt).to be_within(1e-10).of(0.3)
  end

  it 'round-trips a full lifecycle' do
    created = client.create_debt(label: 'pick caching layer', debt_type: :deferred_decision, principal: 0.4)
    expect(created[:created]).to be true
    debt_id = created[:debt_id]

    client.accrue_interest
    report = client.debt_report
    expect(report[:total_debt]).to be > 0.4

    repaid = client.repay_debt(debt_id: debt_id, amount: 99.0)
    expect(repaid[:repaid]).to be true

    pruned = client.prune_repaid
    expect(pruned[:pruned]).to eq(1)

    final = client.total_debt
    expect(final[:total_debt]).to eq(0.0)
  end
end
