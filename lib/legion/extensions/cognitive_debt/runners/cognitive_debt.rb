# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebt
      module Runners
        module CognitiveDebt
          def create_debt(label:, debt_type:, principal: Helpers::Constants::DEFAULT_PRINCIPAL,
                          domain: 'general', engine: nil, **)
            eng = engine || default_engine
            Legion::Logging.debug "[cognitive_debt] create debt label=#{label} type=#{debt_type} principal=#{principal}"
            eng.create_debt(label: label, debt_type: debt_type, principal: principal, domain: domain)
          end

          def repay_debt(debt_id:, amount: Helpers::Constants::REPAYMENT_RATE, engine: nil, **)
            eng = engine || default_engine
            Legion::Logging.debug "[cognitive_debt] repay debt_id=#{debt_id[0..7]} amount=#{amount}"
            eng.repay_debt(debt_id: debt_id, amount: amount)
          end

          def accrue_interest(engine: nil, **)
            eng = engine || default_engine
            result = eng.accrue_all_interest
            Legion::Logging.debug "[cognitive_debt] accrued interest on #{result[:accrued]} debts total_debt=#{result[:total_debt]}"
            result
          end

          def total_debt(engine: nil, **)
            eng = engine || default_engine
            cost = eng.total_debt
            Legion::Logging.debug "[cognitive_debt] total_debt=#{cost}"
            { total_debt: cost }
          end

          def debt_by_type(debt_type:, engine: nil, **)
            eng = engine || default_engine
            eng.debt_by_type(debt_type: debt_type)
          end

          def debt_by_domain(domain:, engine: nil, **)
            eng = engine || default_engine
            eng.debt_by_domain(domain: domain)
          end

          def most_costly(limit: 10, engine: nil, **)
            eng = engine || default_engine
            eng.most_costly(limit: limit)
          end

          def oldest_debts(limit: 10, engine: nil, **)
            eng = engine || default_engine
            eng.oldest_debts(limit: limit)
          end

          def debt_report(engine: nil, **)
            eng = engine || default_engine
            report = eng.debt_report
            Legion::Logging.debug "[cognitive_debt] report total_debt=#{report[:total_debt]} active=#{report[:active_count]}"
            report
          end

          def prune_repaid(engine: nil, **)
            eng = engine || default_engine
            result = eng.prune_repaid
            Legion::Logging.debug "[cognitive_debt] pruned #{result[:pruned]} repaid debts remaining=#{result[:remaining]}"
            result
          end

          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          private

          def default_engine
            @default_engine ||= Helpers::DebtEngine.new
          end
        end
      end
    end
  end
end
