# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebt
      module Helpers
        module Constants
          MAX_DEBTS      = 300
          INTEREST_RATE  = 0.05
          DEFAULT_PRINCIPAL = 0.3
          REPAYMENT_RATE = 0.1

          SEVERITY_LABELS = {
            (0.0...0.2)            => :negligible,
            (0.2...0.4)            => :minor,
            (0.4...0.6)            => :moderate,
            (0.6...0.8)            => :severe,
            (0.8..Float::INFINITY) => :critical
          }.freeze

          DEBT_TYPES = %i[
            deferred_decision
            unprocessed_input
            incomplete_analysis
            pending_integration
            unresolved_conflict
          ].freeze
        end
      end
    end
  end
end
