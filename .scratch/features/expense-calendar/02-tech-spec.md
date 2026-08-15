# 02 — Tech spec · expense-calendar

Implements **Variant A** (approved at gate 1): `☰ List / ▦ Month` toggle under the hero card;
in Month mode a pay-cycle-aligned grid card, with the selected day's expenses inline below it.

## Data model

**No SwiftData changes. No migration.** The calendar is a pure projection of the existing
`Expense` + `PayCycle` types. The only new state is view state (`mode`, `selectedDay`) held in
`ExpensesView`, so nothing is persisted and nothing syncs.

New pure value types in `Features/Expenses/CycleCalendar.swift` (no SwiftUI, no side effects —
this is the behaviour oracle, same pattern as `ExpenseDayGrouping.swift`):

```swift
/// One cell in the grid.
struct CalendarDay: Identifiable {
    let date: Date          // startOfDay
    let inCycle: Bool       // false ⇒ leading/trailing filler, greyed, not tappable
    let total: Decimal      // 0 for out-of-cycle cells, always
    let count: Int
    var id: Date { date }
}

/// The whole grid for one pay cycle.
struct CycleCalendar {
    let weeks: [[CalendarDay]]   // each row exactly 7, ordered by calendar.firstWeekday
    let maxDayTotal: Decimal     // largest in-cycle day total; 0 if the cycle is empty
}

/// Emphasis buckets for the printed total. Weight — not color — is the carrier
/// (guardrail: never color alone).
enum DayIntensity { case none, light, medium, heavy, heaviest }

func cycleCalendar(for: PayCycle, expenses: [Expense], calendar: Calendar) -> CycleCalendar
func dayIntensity(total: Decimal, max: Decimal) -> DayIntensity
func defaultSelectedDay(in: CycleCalendar, today: Date, calendar: Calendar) -> Date?

/// "145k" / "80k" / nil for a day with no spend. Revised 2026-08-16: the cell prints
/// the day's total instead of a dot, and a ~48pt column can't hold "Rp145.000".
func abbreviatedDayTotal(_ total: Decimal) -> String?
```

Rules:
- Grid spans **whole weeks**: from the start-of-week containing `cycle.start` through the
  end-of-week containing `cycle.lastDay()`. `calendar.firstWeekday` decides the column order
  (so a Monday-first locale renders Monday-first).
- `inCycle = cycle.contains(day)`; both bounds are already start-of-day so the half-open
  `[start, end)` interval maps cleanly onto cells.
- Day totals come from `expenseDayGroups(...)` — the **existing** grouping function — so the
  calendar and the list can never disagree about what belongs to a day. Expenses are filtered
  to the cycle first, so an out-of-cycle cell is always `total: 0, count: 0` even when an
  expense exists on that date (the 20 Jul fixture proves this).
- `dayIntensity`: `total == 0 || max == 0` → `.none`; otherwise by ratio to `max` —
  `> 0.75` heaviest, `> 0.50` heavy, `> 0.25` medium, else light. It selects the printed
  total's **weight + tone** (bold/text → regular/secondary), not a dot size.
- `abbreviatedDayTotal`: nil for a zero/negative day; otherwise the amount rounded to the
  nearest thousand with a `k` suffix, floored at `1k` so any nonzero day reads as spending.
  No decimals and no thousands separator — both are locale-dependent and would collide with
  the app's own `Rp145.000` convention inside a 4-glyph budget. A millions-scale day simply
  reads `1200k`, which still fits.
- `defaultSelectedDay`: today if today is in the cycle; else the most recent in-cycle day with
  spending; else `cycle.lastDay()`; `nil` only if the cycle somehow has no days.

## Files touched

- `ExpenseKu/ExpenseKu/Features/Expenses/CycleCalendar.swift` **(new)** — the pure logic above.
- `ExpenseKu/ExpenseKu/Features/Expenses/CycleCalendarView.swift` **(new)** — `CycleCalendarGrid`
  (card: weekday header row + week rows) and `DayCell`. Takes `CycleCalendar` +
  `@Binding var selection: Date?`. Pure presentation; no `@Query`.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpensesView.swift` **(edit)** — `mode` + `selectedDay`
  state, the toggle row, `calendarContent`, and the DEBUG deep-link hook.
- `ExpenseKu/ExpenseKu/DesignSystem/Components.swift` **(edit)** — add `SegmentedToggle`, a
  two-segment capsule (coral active segment on a `textSecondary.opacity(0.1)` track, matching
  `PaydayStepper`'s chrome). A stock `.pickerStyle(.segmented)` can't take the coral selected
  fill cleanly, and this keeps the Warm Cards look.
- `ExpenseKu/ExpenseKu/Shared/DebugLaunch.swift` **(edit)** — doc-comment only (add the two new
  `-startScreen` values).
- `ExpenseKu/ExpenseKu/RootView.swift` **(edit)** — route `calendar` / `calendar-day` to the
  Expenses tab (they are in-tab states, not `fullScreenCover` screens, so they do **not** go in
  `debugScreens`).
- `ExpenseKu/ExpenseKuTests/CycleCalendarTests.swift` **(new)** — the test plan below.

## Control surface (so the screen is screenshot-able)

The calendar is in-tab state, so it follows the `leaderboard` pattern (set the tab in
`RootView`, let the tab's own `.task` flip its state) rather than the `DebugHarness` pattern.

- `-startScreen calendar` — Expenses tab, Month mode, **default** day selected (today).
- `-startScreen calendar-day` — Expenses tab, Month mode, the cycle's **heaviest** day
  selected, so the populated day-list state is screenshot-able.
- `RootView`: add `"calendar", "calendar-day"` to the existing `case` that forces
  `selection = .expenses`.
- `ExpensesView`: `#if DEBUG` in `.task` — set `mode = .calendar`, and for `calendar-day` set
  `selectedDay` to the max-total in-cycle day.
- No `DebugHarness` case, no `debugScreens` entry.

## Fixtures

**No change to `DebugLaunch.seedIfNeeded`.** The existing seed already exercises every state
the grid needs, and other features' committed shots depend on its totals — changing it would
churn them for no gain. What it already gives, for cycle **25/07/2026 ~ 24/08/2026**:

| date | expenses | day total | role in the grid |
|------|----------|-----------|------------------|
| 20 Jul | Latte 25.000 | — | **out-of-cycle expense**: cell is greyed with *no* dot |
| 28 Jul | Ojek + makan 80.000 | 80.000 | heavy dot |
| 2 Aug | Dinner 120.000 + Morning coffee 25.000 | 145.000 | **heaviest** dot; two-row day |
| 5 Aug | Lunch 45.000 | 45.000 | medium dot |
| 6 Aug | Grab home 30.000 | 30.000 | light dot |
| 16 Aug (today) | — | 0 | **today, selected, empty** — the default state |

That covers: four distinct intensity buckets, a multi-expense day, an empty selected day, and
the out-of-cycle leak case. Paging `‹` to the July cycle brings 20 Jul in-cycle, which is the
"paging repaints the grid" evidence.

## Test plan (behaviour oracle)

`ExpenseKuTests/CycleCalendarTests.swift`, written before the view code:

- [ ] `weeks` are all exactly 7 cells, and the first cell is the start-of-week containing
      `cycle.start` (Sun-first default calendar).
- [ ] Every day from `cycle.start` through `cycle.lastDay()` appears exactly once with
      `inCycle == true`.
- [ ] Leading filler (19–24 Jul) and trailing filler (25–29 Aug) are `inCycle == false`.
- [ ] Day totals match the fixtures: 2 Aug → `total 145_000, count 2`; 5 Aug → `45_000, 1`.
- [ ] An expense dated outside the cycle contributes nothing: the 20 Jul cell is
      `total 0, count 0` and no in-cycle day's total includes it.
- [ ] `maxDayTotal == 145_000` for the seeded cycle; `0` for an empty cycle.
- [ ] `dayIntensity` buckets, including boundaries: `(0, x) → .none`, `(x, 0) → .none`,
      `(max, max) → .heaviest`, and the .25/.50/.75 ratio edges land in the documented bucket.
- [ ] `abbreviatedDayTotal`: `0 → nil`; `145_000 → "145k"`; `30_000 → "30k"`; rounds to the
      nearest thousand (`145_400 → "145k"`, `145_600 → "146k"`); floors at `"1k"` for a small
      nonzero amount; a millions-scale day stays in thousands (`1_200_000 → "1200k"`).
- [ ] `calendar.firstWeekday == 2` (Monday-first) puts Monday in column 0 and still yields
      whole weeks.
- [ ] Short-month cycle (payday 31, Jan 31 → Feb 28) yields whole weeks with every cycle day
      present exactly once — reuses `PayCycle`'s clamp, proving no new boundary math.
- [ ] `defaultSelectedDay`: today-in-cycle → today; today outside → most recent day with
      spending; cycle with no spending → `cycle.lastDay()`.
- [ ] Regression: `expenseDayGroups` behaviour is untouched (existing
      `ExpenseDayGroupingTests` stay green).

Oracle command: `scripts/shot.sh --test`.

## Interactive flow (simdrive.sh — required)

Coordinates are screenshot pixels on the 1206×2622 shot; the exact numbers get read off
`cal-drive-01` at run time (the grid's cell pitch isn't knowable before the first render).
Every step captures a shot and the shot is Read before moving on.

- `simdrive.sh launch -- -seedSampleData -startTab expenses`
- [ ] `shot cal-drive-01` → expect the existing list view, plus the new toggle with **List** active.
- [ ] `tap <Month segment>` → `shot cal-drive-02` → expect: grid card replaces the list; 16 Aug
      ringed **and** coral-filled; dots on 28 Jul / 2 / 5 / 6 Aug in four distinct sizes;
      19–24 Jul and 25–29 Aug greyed; **20 Jul greyed with no dot**; day section reads
      `TODAY · Rp0` with the "No expenses on Sun, 16 Aug" message.
- [ ] `tap <2 Aug cell>` → `shot cal-drive-03` → expect: coral fill moves to 2 Aug, ring stays
      on 16 Aug; header `SUN, 2 AUGUST · Rp145.000`; two cards, **Dinner Rp120.000 above
      Morning coffee Rp25.000** (newest time first — the existing sort rule holds here too).
- [ ] `tap <Dinner card>` → `shot cal-drive-04` → expect the expense editor sheet, amount 120.000.
- [ ] `key escape` (or tap Cancel) → `shot cal-drive-05` → expect back on the calendar with
      2 Aug **still selected** (selection survives the editor round-trip).
- [ ] `tap <‹ arrow>` → `shot cal-drive-06` → expect the July cycle (25/06 ~ 24/07): hero total
      changes, grid repaints, **20 Jul now in-cycle and dotted**, selection resets to that
      cycle's default day.
- [ ] `tap <› arrow>` → `shot cal-drive-07` → expect the August cycle back, grid as in step 2.
- [ ] `tap <List segment>` → `shot cal-drive-08` → expect the day-grouped list, visually
      identical to `cal-drive-01`.
- [ ] `tap <empty in-cycle day, e.g. 13 Aug>` (after re-entering Month) → `shot cal-drive-09` →
      expect the day empty-state, not a blank region.

Static shots additionally required: `shot.sh calendar -- -seedSampleData -startScreen calendar`,
`calendar-day`, both `-a` dark variants, and one iPad run to confirm the grid sits in the
sidebar column with the editor still in the detail pane.

## Risks / guardrails touched

- **Pay-cycle model** (hard guardrail) — the grid is cycle-aligned, not month-aligned, and
  `‹ ›` remain the only way to change period. The hero total and the grid always cover the
  same range. Out-of-cycle cells exist only as greyed filler and carry no data.
- **No new spending concept** — intensity is a ratio of existing day totals to the cycle's own
  max. No budget, target, remaining, or per-day limit is introduced or implied.
- **Never encode meaning in color alone** — the printed total is itself the primary channel,
  and its *weight* ramps with intensity alongside its tone; every cell gets an accessibility
  label ("Thursday 6 August, Rp30.000, 1 expense" / "…, no expenses") and the selected cell
  adds `.isSelected`.
- **Dynamic Type** — the grid stays 7 columns at every size (a reflowing calendar isn't a
  calendar). The date number scales; at accessibility sizes there's no room for a second line,
  so the cell drops the printed total and bolds the date instead. Labels are unchanged either
  way, so a screen-reader user still gets the exact amount.
- **Money format** — the cell's `145k` is an **abbreviation, not a money string**: it drops the
  `Rp`, rounds, and is never the authoritative figure. The authoritative amounts next to it —
  the day header total and every row — still use `formattedIDR()` unchanged, and the cell's
  VoiceOver label reads the full `formattedIDR()` value. Guardrail intact.
- **iPad/Mac split** — grid renders in the sidebar column where the list lives today; the
  editor stays in the detail pane. Verified by an iPad shot, not assumed.
- **Delete** — the day section keeps `.onDelete`, operating on that day's array only. Deleting
  the last expense of the selected day must leave the day selected and show its empty state
  (covered by drive step 9's state).
- **Perf** — same `@Query` and the same per-cycle filter the list already does; the grid adds
  one `Dictionary(grouping:)` over the cycle's expenses. No new fetches.

---
Gate 2: user agrees the approach is sound before any code is written.
