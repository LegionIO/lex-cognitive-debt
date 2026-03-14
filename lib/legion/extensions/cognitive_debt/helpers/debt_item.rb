# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDebt
      module Helpers
        class DebtItem
          attr_reader :id, :label, :debt_type, :principal, :accrued_interest,
                      :domain, :created_at, :repaid_at

          def initialize(label:, debt_type:, principal:, domain:)
            @id               = SecureRandom.uuid
            @label            = label
            @debt_type        = debt_type.to_sym
            @principal        = principal.clamp(0.0, Float::INFINITY)
            @accrued_interest = 0.0
            @domain           = domain
            @created_at       = Time.now.utc
            @repaid_at        = nil
          end

          def total_cost
            (@principal + @accrued_interest).round(10)
          end

          def accrue!
            return if repaid?

            @accrued_interest = (@accrued_interest + (Constants::INTEREST_RATE * @principal)).round(10)
          end

          def repay!(amount: Constants::REPAYMENT_RATE)
            return if repaid?

            @accrued_interest = [0.0, @accrued_interest - amount].max.round(10)
            @principal        = [0.0, @principal - amount].max.round(10)
            @repaid_at        = Time.now.utc if @principal.zero? && @accrued_interest.zero?
          end

          def repaid?
            !@repaid_at.nil?
          end

          def severity_label
            cost = total_cost
            Constants::SEVERITY_LABELS.each do |range, label|
              return label if range.cover?(cost)
            end
            :critical
          end

          def age_seconds
            reference = @repaid_at || Time.now.utc
            (reference - @created_at).to_f
          end

          def to_h
            {
              id:               @id,
              label:            @label,
              debt_type:        @debt_type,
              principal:        @principal,
              accrued_interest: @accrued_interest,
              total_cost:       total_cost,
              domain:           @domain,
              severity:         severity_label,
              age_seconds:      age_seconds.round(2),
              created_at:       @created_at.iso8601,
              repaid_at:        @repaid_at&.iso8601,
              repaid:           repaid?
            }
          end
        end
      end
    end
  end
end
