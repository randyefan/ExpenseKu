# STATUS — expense-search

**Current stage:** 4 Ship — DONE. Merged to `main` as 8521337 (not pushed).
**Branch:** feature/expense-search — 6 commits, merged --no-ff into main 2026-08-28.
Suite green on merged main: 164 passed, 0 failed.

## Gate log
<!-- one line per passed gate: stage · date · what was approved -->
- Stage 0 Brief · 2026-08-28 · approved: all-time search on the Expenses tab via a pull-down
  `.searchable` bar; matches note + category + people + account; results are a flat
  newest-first list with a count + summed total, tappable to edit, narrowed by category and
  date-range filter chips. No model change.
- Stage 1 Wireframe · 2026-08-28 · approved with one change: **A1** (date on each result row)
  + **B1** (two `FilterChip` menus under the search bar); cycle header/coral total/List-Month
  toggle hide while a query is active; **swipe-to-delete kept in results** (user's amendment
  to the drawn wireframe, which had proposed omitting it).
- Stage 2 Tech spec · 2026-08-28 · approved as written: pure `ExpenseSearchResults` layer, no
  model change, multi-word AND matching, `FilterChip` moved to `DesignSystem/`, `simdrive.sh`
  gains `swipe`, and the `.searchable`-drawer risk to be settled by screenshot in stage 3.
- Stage 3 Build · 2026-08-28 · approved: 164 tests green + the interactive flow above;
  `.searchToolbarBehavior(.minimize)` accepted (🔍 keeps the trailing toolbar slot, coral +
  moves inboard); tap-to-edit confirmed by hand.
- Stage 4 Ship · 2026-08-28 · 6 commits on feature/expense-search, merged --no-ff into main
  as 8521337. Not pushed.

## Stage 3 build notes (2026-08-28)

**Unit oracle:** 164 tests, 0 failures, `scripts/shot.sh --test` exit 0. 22 new
(18 `ExpenseSearchTests` + 4 `SearchDateLabelTests`).

**Code:** pure layer `ExpenseSearch.swift` (`ExpenseSearchResults` + `ExpenseSearchMatch`) and
`SearchDateLabel.swift`; views `ExpenseSearchLens` / `ExpenseSearchSummary` /
`ExpenseSearchFilters`; `ExpenseRow`+`ExpenseListRow` gained an optional `dateLabel` (nil
default ⇒ cycle list and calendar unchanged); `ExpensesView` gained the search state, the
branch and the `.searchable`; `FilterChip.swift` moved to `DesignSystem/`.
No model change, as spec'd.

**Two deviations from the approved spec, both forced by what the simulator showed:**

1. **`.searchToolbarBehavior(.minimize)` instead of the pull-down drawer.** Risk 1 in the tech
   spec came true: `.navigationBarDrawer(displayMode: .automatic)` does *not* hide here — it
   only auto-hides when it can couple to the scroll view directly beneath it, and this tab's
   `List` sits under the cycle header + lens toggle inside a `VStack`. Shot `s01-idle.png`
   shows the field parked permanently above the cycle card (the "always visible" option the
   user rejected at gate 1). The iOS 26 fallback named in the spec was applied and delivers
   the approved intent — zero resting cost, one tap to open (`s01b-idle-min.png`).
   **Side effect to accept or reject:** the 🔍 takes the trailing toolbar slot, pushing the
   coral **+** inward. On the first-run empty state no 🔍 is offered at all and **+** returns
   to the corner (`s13-virgin.png`).
2. **`simdrive.sh` gained `press` as well as the spec'd `swipe`.** `swipe` was planned;
   `press` (press-hold-release, default 140 ms) was added while diagnosing the tap issue
   below. Two useful harness findings: `key` sends whole strings (`key kopi` types the word),
   and an instant `tap` is unreliable on controls inside a `List`.

**Interactive verification (`simdrive.sh`) — what was proved:**

| Step | Shot | Result |
|------|------|--------|
| Idle, search minimized | `s01b-idle-min.png` | 🔍 in toolbar, no vertical cost ✅ |
| Tap 🔍 → field opens | `s02b-open.png` | expands, cycle view intact underneath ✅ |
| Type "kopi" (live) | `s03b-results.png` | typed **"Kopi"** autocapitalised and still matched — case-folding proved live. Header/total/toggle hidden; 4 results · Rp 140.000; dates incl. "18 Dec 25" ✅ |
| Period chip → menu | `s04-menu.png` | five presets, "All time" checked ✅ |
| Pick "This year" | `s05-filtered.png` | Dec-2025 row drops; 4→3, 140.000→105.000 ✅ |
| Swipe-to-delete | `s09-swipe.png` | Delete revealed ✅ |
| Confirm delete | `s10-deleted.png` | 4→3, 140.000→115.000; summary recounts + re-totals ✅ |
| Cancel search | `s11-restored.png` | same cycle, same lens, 🔍 back ✅ |
| First run, empty store | `s13-virgin.png` | **no** search field offered; + back in corner ✅ |
| Dark mode | `search-dark.png` | reads correctly ✅ |
| No results | `search-empty.png` | filters stay, query named back ✅ |

**"Tapping a result opens it in the editor" — VERIFIED BY HAND (2026-08-28).** The user
confirmed the editor opens for a real finger. This is a **`simdrive.sh` limitation, not a
bug**: cliclick's synthetic events do not activate a `Button` inside a `List`. Recorded as a
gotcha in `.scratch/features/AGENTS.md` so later features don't re-diagnose it.

The investigation that led there, kept because it maps what the harness can and cannot drive:
- It fails **identically on clean `main`** with the feature stashed — the cycle list's own rows
  don't open the editor either (`c02-tapped.png`). **Not a regression from search.**
- Sheet presentation from this view works: the **+** button opens the editor sheet
  (`diag02-plus.png`).
- Not the size class: hardcoding `editsInSheet = true` changed nothing (`diag01.png`); reverted.
- Not simply a swallowed/too-fast click: gestures reach the same `List` fine (swipe-to-delete
  works), and `press` with a dwell works on other rows.
- `dismissesKeyboardOnOutsideTap()` is defined but never called, so it is not the cause.
- **Answer:** `Button` + `.buttonStyle(.plain)` inside a `List` ignores cliclick's synthetic
  events. A real finger works. Nothing to fix in the app.

## Notes / open questions
- Stage 0 answers (2026-08-28): scope = **all time** (escapes the cycle lens); match =
  **note + category + people + account**; entry = **pull-down `.searchable` bar** on the
  Expenses tab; v1 includes **result total**, **tap-to-edit**, and **filter chips**.
- Reuse candidates found in the codebase: `Features/Insights/DateRangeFilter.swift`
  (All time / Last 30 days / This month / This pay period / This year),
  `Features/Insights/FilterChip.swift`, `Features/Insights/PeriodFilterChips.swift`.
  `ExpensesView` already holds the full `@Query(sort: \Expense.date, order: .reverse)` array,
  so an all-time search needs no new fetch.
- Open for Stage 1: exact filter-chip layout (inline row vs. a filter sheet), and whether the
  List/Month toggle hides while a query is active.
