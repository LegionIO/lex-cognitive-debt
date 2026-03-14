# lex-cognitive-debt

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive debt modeling for brain-modeled agentic AI — deferred processing that accrues interest over time. Models the accumulation of unresolved cognitive tasks (deferred decisions, unprocessed input, incomplete analysis, pending integration, unresolved conflicts) as debt items that compound interest until repaid.

## Gem Info

- **Gem name**: `lex-cognitive-debt`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveDebt`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_debt/
  cognitive_debt.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    debt_engine.rb
    debt_item.rb
  runners/
    cognitive_debt.rb
```

## Key Constants

From `helpers/constants.rb`:

- `DEBT_TYPES` — `%i[deferred_decision unprocessed_input incomplete_analysis pending_integration unresolved_conflict]`
- `MAX_DEBTS` = `300`
- `INTEREST_RATE` = `0.05`, `DEFAULT_PRINCIPAL` = `0.3`, `REPAYMENT_RATE` = `0.1`
- `SEVERITY_LABELS` — `0.0-0.2` = `:negligible`, `0.2-0.4` = `:minor`, `0.4-0.6` = `:moderate`, `0.6-0.8` = `:severe`, `0.8+` = `:critical`

## Runners

All methods in `Runners::CognitiveDebt`:

- `create_debt(label:, debt_type:, principal: DEFAULT_PRINCIPAL, domain: 'general')` — creates a new debt item
- `repay_debt(debt_id:, amount: REPAYMENT_RATE)` — reduces principal by amount; debt is cleared when principal <= 0
- `accrue_interest` — applies `INTEREST_RATE` to all active debts; returns accrued count and total debt
- `total_debt` — sum of all outstanding principals
- `debt_by_type(debt_type:)` — all debts of a given type
- `debt_by_domain(domain:)` — all debts in a given domain
- `most_costly(limit: 10)` — top debts by current principal
- `oldest_debts(limit: 10)` — debts sorted by age
- `debt_report` — full report: total debt, active count, by-type breakdown
- `prune_repaid` — removes fully-repaid debts; returns pruned/remaining counts

## Helpers

- `DebtEngine` — manages debt items. `accrue_all_interest` iterates active debts and applies `INTEREST_RATE`. `total_debt` sums current principals.
- `DebtItem` — has `label`, `debt_type`, `principal`, `domain`, `created_at`. `repay!(amount)` decrements principal. `paid_off?` checks principal <= 0.

## Integration Points

- `lex-cognitive-disengagement` handles goal abandonment; debt models what remains after the disengaged goal leaves behind unprocessed work (residual principal).
- `lex-tick` can call `accrue_interest` each tick to compound outstanding debt, and `debt_report` to check total debt load before deciding processing depth.
- `unresolved_conflict` debt type connects directly to `lex-conflict` — conflicts that are neither resolved nor escalated become debt items accruing interest.

## Development Notes

- `accrue_interest` compounds — debt grows exponentially if never repaid. `INTEREST_RATE = 0.05` per accrue call means ~60% growth over a 10-tick cycle without repayment.
- `prune_repaid` should be called periodically to keep the debt store from filling with zero-principal items.
- Debt types are not validated against `DEBT_TYPES` constant in the runner — any string/symbol is accepted. Type enforcement is the caller's responsibility.
- Runners log accrual and repayment events via `Legion::Logging.debug`.
