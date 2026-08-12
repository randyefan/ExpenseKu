# STATUS — person-expenses

**Current stage:** 4 Ship — DONE (committed 908aa2c on feature/person-expenses)
**Branch:** feature/person-expenses

## Gate log
<!-- one line per passed gate: stage · date · what was approved -->
- Stage 0 Brief · 2026-08-12 · approved as written (edit-through stays out of scope).
- Stage 1 Wireframe · 2026-08-12 · approved Variant A (flat newest-first list); Variant B dropped.
- Stage 2 Tech spec · 2026-08-12 · approved "build it" (no schema; pure fn + new view + nav link).
- Stage 3 Build · 2026-08-12 · approved "ship it" (unit green, shots match Variant A, tap-through verified).
- Stage 4 Ship · 2026-08-12 · committed 908aa2c.

## Stage 3 — build + verify results
Code:
- `Analytics/PeopleLeaderboard.swift` — added pure `expenses(for:from:category:account:dateRange:)`.
- `Features/Insights/PersonExpensesView.swift` (new) — `PersonExpensesRoute` + detail screen.
- `Features/Insights/InsightsView.swift` — `Destination.personExpenses`; nav destination; debug hook.
- `Features/Insights/PeopleLeaderboardView.swift` — rows are NavigationLinks; added chevron.
- `Shared/DebugLaunch.swift` + `RootView.swift` — `-startScreen person-detail` deep-link.
- `ExpenseKuTests/PeopleLeaderboardTests.swift` — 5 new tests.

Oracles:
- **Unit:** `scripts/shot.sh --test` GREEN, incl. 5 new `expensesForPerson*` tests (filter,
  newest-first sort, filters, empty, reconciliation with `ranked` row).
- **Visual:** `shots/person-detail.png` (+`-dark`) match approved Variant A — header card
  (avatar/name/total/"N expenses · range"), flat newest-first cards w/ aligned date line,
  attribution caption. Dark mode reads.
- **Interactive (simdrive):**
  - `drive-leaderboard.png` — rows now show a chevron affordance.
  - `drive-detail-fadil.png` — tapped Fadil (rank 2) → Fadil detail; total **Rp145.000 / 2
    expenses** reconciles with the row; list newest-first (2 Aug → 20 Jul).
  - `drive-back6.png` — back button pops the stack (detail → leaderboard → Insights).
  - Note: the small top-left back button is flaky under cliclick (first-tap-after-shot
    swallow + a title-bar y-offset; origin_y≈75, aim ~pixel-y 300–320 to hit it). Row taps
    (large targets) are reliable. "Filters intact on back" is default NavigationStack
    @State + the route carrying category/account/range forward.

## Notes / open questions
- Source: user asked to make leaderboard rows tappable → drill into a person's expenses.
- Attribution note for detail total: full amount credited to each companion (unchanged).
