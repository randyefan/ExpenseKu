# STATUS — daily-total

**Current stage:** 4 Ship — committed 04071ea on feature/daily-total (awaiting final confirm)
**Branch:** feature/daily-total (created at stage 4)

## Gate log
<!-- one line per passed gate: stage · date · what was approved -->
- Stage 0 Brief · 2026-08-11 · approved: add a per-day total to each day group in the Expenses list, IDR-formatted, current cycle only, no model change.
- Stage 1 Wireframe · 2026-08-11 · approved Variant A (subtle, header-styled total on the trailing edge of the day header).
- Stage 2 Tech spec · 2026-08-11 · approved: computed total on ExpenseDayGroup, rendered in day-header HStack, 3 sum tests, no model change.
- Stage 3 Build · 2026-08-11 · approved: day-header totals (light+dark) matching Variant A + green suite.
- Stage 4 Ship · 2026-08-11 · commit 04071ea on feature/daily-total.

## Stage 3 build notes
- `ExpenseDayGroup.total: Decimal` (computed sum) added to ExpenseDayGrouping.swift.
- `ExpensesView.DayGroup` gains `total`; day-section header is now an HStack (title · Spacer ·
  total). Total = dsCaption/semibold/secondary/monospacedDigit, IDR via `.formattedIDR()`.
- 3 new tests in ExpenseDayGroupingTests.swift (sum / per-group independence / single) — full
  suite green via `scripts/shot.sh --test`.
- Shots: shots/daily-total.png (light) + daily-total-dark.png — day headers show totals
  (Thu 30.000, Wed 45.000, Sun 145.000). Matches approved Variant A; coral reserved for hero.

## Notes / open questions
- Day grouping already existed (`ExpenseDayGrouping.swift`); no model change.
