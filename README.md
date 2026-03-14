# lex-cognitive-debt

Cognitive debt modeling for LegionIO. Deferred processing that accrues interest over time.

## What It Does

When the agent defers decisions, leaves inputs unprocessed, abandons partial analysis, or fails to integrate new information, cognitive debt accumulates. Like financial debt, it compounds with interest — the longer you defer, the more costly resolution becomes. This extension tracks that debt, applies interest each cycle, and supports structured repayment.

Five debt types are modeled: deferred decision, unprocessed input, incomplete analysis, pending integration, and unresolved conflict.

## Usage

```ruby
client = Legion::Extensions::CognitiveDebt::Client.new

debt = client.create_debt(
  label: 'deferred analysis of conflicting trust signals',
  debt_type: :incomplete_analysis,
  principal: 0.5,
  domain: 'trust'
)

client.accrue_interest
client.total_debt
# => { total_debt: 0.525 }  # 5% interest applied

client.repay_debt(debt_id: debt[:id], amount: 0.2)
client.debt_report
client.prune_repaid
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
