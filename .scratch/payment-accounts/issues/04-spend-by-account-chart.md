# 04 — Spend-by-Account chart

Status: resolved
Blocked by: 01

Add a spend-by-account chart to Insights, reusing the SpendSummary pattern.

## Scope

- `Analytics/SpendSummary.swift`: add `byAccount(from:dateRange:)` → `[AccountSpend]`
  (or reuse a generic shape), with an **"Unassigned"** bucket for expenses whose account is nil.
- `Features/Insights/SpendByAccountChart.swift` — bars + IDR annotations, like
  `SpendByCategoryChart`.
- Add it to `InsightsView` beside the other charts, under the shared **Period** filter.

## Definition of done

- Chart renders correct per-account totals (incl. Unassigned) and updates with the period.
- Builds on the iOS 17 simulator.

## Comments

Resolved — implemented and verified: full test build succeeds on the iOS simulator (iPhone 17 Pro) and all 16 unit tests pass (incl. 6 new AccountAnalyticsTests).
