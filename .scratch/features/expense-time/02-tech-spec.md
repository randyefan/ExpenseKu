# 02 — Tech spec · expense-time

Chosen UX: **Variant A** — the editor's "Date" row shows date **and** time inline.

## Data model
- **No schema change.** `Expense.date` is already a full `Date` (date + time). No new field,
  no migration, no CloudKit impact.

## Files touched
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseEditorView.swift` (edit) — change the Date
  `DatePicker` to `displayedComponents: [.date, .hourAndMinute]` and relabel `"Date"` →
  `"Date & Time"`. (Both iOS and macOS use the shared `detailRows`, so this is one edit.)
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpensesView.swift` (edit) — extract the day-grouping
  logic (`Dictionary(grouping:)` + within-day `sorted { $0.date > $1.date }`) into a pure,
  testable free function so the "sort by time" behaviour has an oracle. The view calls it;
  no visual change.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseDayGrouping.swift` (new) — the extracted pure
  function: `expenseDayGroups(_ expenses:, calendar:) -> [(day: Date, expenses: [Expense])]`.
  Groups by `calendar.startOfDay`, days descending, expenses within a day by `date` descending.
- `ExpenseKu/ExpenseKuTests/ExpenseDayGroupingTests.swift` (new) — behaviour oracle (below).
- `ExpenseKu/ExpenseKu/Shared/DebugLaunch.swift` (edit) — give a couple of same-day fixtures
  distinct times so the screenshot demonstrates intra-day ordering (see Fixtures).

## Control surface (so the screen is screenshot-able)
- **Already exists.** The editor is reachable via `-startScreen editor` (`DebugHarness.swift`
  case `"editor"`, already in `RootView.debugScreens`). No control-surface change needed.
- Screenshot command: `scripts/shot.sh expense-time -- -seedSampleData -startScreen editor`
  (and `-a` for dark).

## Fixtures
- In `DebugLaunch.seedIfNeeded`, extend the `day(_:_:)` helper usage: add an optional
  `hour`/`minute`, and give two expenses the **same day** with **different times** (e.g.
  a `08:15` and a `20:30` on Aug 2) so the seeded list visibly orders by time. Keeps the
  existing account-less edge case. This only affects DEBUG seed data.

## Test plan (behaviour oracle)
Written first in stage 3, run via `scripts/shot.sh --test`:
- [ ] `testWithinDaySortedByTimeDescending` — two expenses on the same calendar day with
      different times come back newest-time-first.
- [ ] `testDaysSortedDescending` — groups are ordered by day, most recent day first.
- [ ] `testSameTimestampStable` — equal timestamps don't crash / drop rows (count preserved).
- [ ] `testGroupingUsesStartOfDay` — expenses at 00:05 and 23:55 of one day land in one group.

## Risks / guardrails touched
- **Model/vocab/3-tab:** none changed. Label goes "Date" → "Date & Time" (a clarification,
  not a vocabulary change to the domain nouns).
- **Money format / dark mode / Dynamic Type / VoiceOver:** untouched; `DatePicker` is native
  and already localized.
- **Revamp screenshots:** editing seed times could shift the revamp branch's frozen shots, but
  this work is on `feature/expense-time`, independent of `revamp/warm-cards`.
- Timezone: uses `Calendar.current` exactly as today; no new timezone behaviour.

---
Gate 2: user agrees the approach is sound before any code is written.
