# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebt::Helpers::Constants do
  describe 'MAX_DEBTS' do
    it 'is 300' do
      expect(described_class::MAX_DEBTS).to eq(300)
    end
  end

  describe 'INTEREST_RATE' do
    it 'is 0.05' do
      expect(described_class::INTEREST_RATE).to eq(0.05)
    end
  end

  describe 'DEFAULT_PRINCIPAL' do
    it 'is 0.3' do
      expect(described_class::DEFAULT_PRINCIPAL).to eq(0.3)
    end
  end

  describe 'REPAYMENT_RATE' do
    it 'is 0.1' do
      expect(described_class::REPAYMENT_RATE).to eq(0.1)
    end
  end

  describe 'SEVERITY_LABELS' do
    it 'is a frozen hash' do
      expect(described_class::SEVERITY_LABELS).to be_frozen
    end

    it 'maps low cost to :negligible' do
      label = described_class::SEVERITY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:negligible)
    end

    it 'maps 0.3 to :minor' do
      label = described_class::SEVERITY_LABELS.find { |range, _| range.cover?(0.3) }&.last
      expect(label).to eq(:minor)
    end

    it 'maps 0.5 to :moderate' do
      label = described_class::SEVERITY_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:moderate)
    end

    it 'maps 0.7 to :severe' do
      label = described_class::SEVERITY_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:severe)
    end

    it 'maps 0.9 to :critical' do
      label = described_class::SEVERITY_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:critical)
    end
  end

  describe 'DEBT_TYPES' do
    it 'includes all five expected types' do
      expect(described_class::DEBT_TYPES).to include(
        :deferred_decision,
        :unprocessed_input,
        :incomplete_analysis,
        :pending_integration,
        :unresolved_conflict
      )
    end

    it 'has exactly five types' do
      expect(described_class::DEBT_TYPES.size).to eq(5)
    end

    it 'contains only symbols' do
      expect(described_class::DEBT_TYPES).to all(be_a(Symbol))
    end
  end
end
