# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebt
      module Helpers
        class DebtEngine
          def initialize
            @debts = {}
          end

          def create_debt(label:, debt_type:, principal: Constants::DEFAULT_PRINCIPAL, domain: 'general')
            return { created: false, reason: :debt_type_invalid } unless Constants::DEBT_TYPES.include?(debt_type.to_sym)
            return { created: false, reason: :limit_reached } if @debts.size >= Constants::MAX_DEBTS

            item = DebtItem.new(
              label:     label,
              debt_type: debt_type,
              principal: principal,
              domain:    domain
            )
            @debts[item.id] = item
            { created: true, debt_id: item.id, debt: item.to_h }
          end

          def repay_debt(debt_id:, amount: Constants::REPAYMENT_RATE)
            item = @debts[debt_id]
            return { found: false } unless item
            return { found: true, repaid: false, reason: :already_repaid } if item.repaid?

            item.repay!(amount: amount)
            { found: true, repaid: true, debt_id: debt_id, debt: item.to_h }
          end

          def accrue_all_interest
            count = 0
            @debts.each_value do |item|
              next if item.repaid?

              item.accrue!
              count += 1
            end
            { accrued: count, total_debt: total_debt }
          end

          def total_debt
            @debts.values.reject(&:repaid?).sum(&:total_cost).round(10)
          end

          def debt_by_type(debt_type:)
            type = debt_type.to_sym
            items = @debts.values.select { |d| d.debt_type == type && !d.repaid? }
            { debt_type: type, count: items.size, items: items.map(&:to_h) }
          end

          def debt_by_domain(domain:)
            items = @debts.values.select { |d| d.domain == domain && !d.repaid? }
            { domain: domain, count: items.size, items: items.map(&:to_h) }
          end

          def most_costly(limit: 10)
            items = @debts.values
                          .reject(&:repaid?)
                          .sort_by { |d| -d.total_cost }
                          .first(limit)
            { count: items.size, items: items.map(&:to_h) }
          end

          def oldest_debts(limit: 10)
            items = @debts.values
                          .reject(&:repaid?)
                          .sort_by(&:created_at)
                          .first(limit)
            { count: items.size, items: items.map(&:to_h) }
          end

          def debt_report
            active = @debts.values.reject(&:repaid?)
            by_type = Constants::DEBT_TYPES.to_h do |type|
              typed = active.select { |d| d.debt_type == type }
              [type, { count: typed.size, total_cost: typed.sum(&:total_cost).round(10) }]
            end

            priority = active.sort_by { |d| -d.total_cost }.first(5)

            {
              total_debt:           total_debt,
              active_count:         active.size,
              repaid_count:         @debts.values.count(&:repaid?),
              by_type:              by_type,
              recommended_priority: priority.map(&:to_h)
            }
          end

          def prune_repaid
            before = @debts.size
            @debts.delete_if { |_id, item| item.repaid? }
            pruned = before - @debts.size
            { pruned: pruned, remaining: @debts.size }
          end

          def to_h
            {
              total_debt:   total_debt,
              active_count: @debts.values.reject(&:repaid?).size,
              total_count:  @debts.size,
              debts:        @debts.values.map(&:to_h)
            }
          end
        end
      end
    end
  end
end
