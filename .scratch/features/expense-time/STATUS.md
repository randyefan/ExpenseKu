# STATUS — expense-time

**Current stage:** 3 Build + verify (awaiting visual gate)
**Branch:** feature/expense-time (created at stage 4)

## Gate log
<!-- one line per passed gate: stage · date · what was approved -->
- Stage 0 Brief · 2026-08-11 · approved: add time input so same-day expenses sort by set time.
- Stage 1 Wireframe · 2026-08-11 · approved Variant A (combined Date+Time row).
- Stage 2 Tech spec · 2026-08-11 · approved: no model change; editor picker + grouping extraction + 4 tests.

## Stage 3 build notes
- Editor: `DatePicker` → `[.date, .hourAndMinute]`, label "Date & Time" (ExpenseEditorView.swift).
- Extracted `expenseDayGroups(_:calendar:)` → new ExpenseDayGrouping.swift; ExpensesView uses it.
- New ExpenseDayGroupingTests.swift (4 tests) — all pass; full suite green via `shot.sh --test`.
- Seed: two Aug-2 expenses at 08:15 / 20:30 to demo intra-day order (DebugLaunch.swift).
- Shots: shots/expense-time.png (light) + expense-time-dark.png — both show the Date/Time row.

## Notes / open questions
- Model already stores a full `Date` (date+time); list already sorts by `\Expense.date`
  reverse and by `$0.date > $1.date` within a day. The only gap is the editor's
  `DatePicker` uses `displayedComponents: .date` — no time input. Feature = add time input.
