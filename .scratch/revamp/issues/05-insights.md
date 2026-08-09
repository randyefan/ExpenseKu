# 05 — Insights (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/insights.png`
Files: `Features/Insights/InsightsView.swift`, `SpendByCategoryChart.swift`,
`SpendByAccountChart.swift`, `SpendOverTimeChart.swift`, `DateRangeFilter.swift`

Reskin the scrolling Insights screen: period filter (All time / Last 30 days / This month /
This pay period / This year; "This pay period" reveals the inline payday stepper), Spend by
Category (horizontal bars + IDR values), Spend by Account (incl. "Unassigned" bar), Spend over
Time (vertical monthly bars), and the link to the People leaderboard. Charts stay Swift Charts;
coral only as a highlight — never encode meaning in color alone (label bars).

## Verify
`scripts/shot.sh insights -- -seedSampleData -startTab insights` vs `refs/insights.png`.
`-a` for dark. `scripts/shot.sh --test`.

## Guardrails
Keep all five presets + the pay-period stepper (ADR-0003). No income/net/budget series.
