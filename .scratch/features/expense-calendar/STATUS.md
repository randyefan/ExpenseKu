# STATUS — expense-calendar

**Current stage:** 4 Ship — DONE (committed on feature/expense-calendar)
**Branch:** feature/expense-calendar

## Gate log
<!-- one line per passed gate: stage · date · what was approved -->
- Stage 0 Brief · 2026-08-16 · approved as written, with three decisions settled:
  pay-cycle-aligned grid (out-of-cycle days greyed), list/calendar toggle in the header
  (list stays default), day cell = date number + intensity dot.
- Stage 1 Wireframe · 2026-08-16 · approved **Variant A** (grid card + selected-day list
  inline). Variant B (day bottom-sheet) dropped — sheet-on-sheet to reach the editor.
- Stage 2 Tech spec · 2026-08-16 · approved "build it" (no schema; pure fn + grid view +
  header toggle; seed frozen).
- **Walk-back** · 2026-08-16 (mid stage 3) · owner changed the day cell: print the day's
  **total** under the date instead of an intensity dot. Brief decision 3, the wireframe's
  cell notation + Dynamic-Type note, and the tech spec were all updated and re-approved
  ("Abbreviated + weighted"). Intensity survives as the number's weight + tone.
- Stage 3 Build · 2026-08-16 · approved "ship it" (91 unit tests green, shots match
  Variant A in light/dark/empty/iPad, 10-step interactive flow verified).
- Stage 4 Ship · 2026-08-16 · committed `10d4d4d` (feature) + `441405b` (simdrive fix).

## Stage 3 — build + verify results

Code:
- `Features/Expenses/CycleCalendar.swift` (new) — pure `CalendarDay` / `CycleCalendar` /
  `cycleCalendar(for:expenses:calendar:)` / `dayIntensity` / `abbreviatedDayTotal` /
  `defaultSelectedDay`. Day totals delegate to the existing `expenseDayGroups`, so the
  calendar and the list can't disagree about a day.
- `Features/Expenses/CycleCalendarView.swift` (new) — `CycleCalendarGrid` + `DayCell`.
- `Features/Expenses/ExpensesView.swift` — `Lens` (list/calendar), `lensToggle`,
  `calendarContent`, `resolvedSelectedDay`, `selectedDayGroup`, `dayPhrase`, shared
  `delete(_:from:)`; DEBUG lens hook.
- `DesignSystem/Components.swift` — new `SegmentedToggle`.
- `Shared/DebugLaunch.swift` + `RootView.swift` — `-startScreen calendar|calendar-day`.
- `ExpenseKuTests/CycleCalendarTests.swift` (new) — 18 tests.
- `scripts/simdrive.sh` — **harness fix**, see "Tooling" below.

Oracles:
- **Unit:** `scripts/shot.sh --test` GREEN, **91 tests, 0 failures** (18 new). Covers grid
  shape/whole weeks, every cycle day exactly once, filler marked out-of-cycle, day totals,
  out-of-cycle expense excluded, `maxDayTotal`, intensity buckets incl. exact ratio edges,
  abbreviation (rounding, 1k floor, millions), Monday-first locale, payday-31 short-month
  clamp, and the three `defaultSelectedDay` fallbacks.
  - Two of the first-draft assertions were wrong, not the code: 20 Jul *is* drawn in the
    August grid (as filler), and a ratio sitting exactly on a threshold stays in the lower
    bucket. Both assertions corrected.
- **Visual:** `shots/calendar.png`, `calendar-day.png`, `calendar-dark.png`,
  `calendar-empty.png`, `ipad-calendar.png` all match approved Variant A.
  - First draft had a real defect the shot caught: dot sizes 4→8pt were indistinguishable
    at 7-across. Superseded by the printed-total redesign anyway.
  - Second defect the shot caught: the selected day's dot was inverted to `Theme.card`, but
    it sits *below* the coral circle on the card background — white on white, invisible.
  - iPad: grid renders in the sidebar column, day rows beneath it, editor in the detail
    pane. Split behaviour unchanged.

### Interactive (simdrive) — the full flow, 10 steps
| step | action | result |
|---|---|---|
| 01 | launch `-seedSampleData -startTab expenses` | List lens is the default; toggle shows List active |
| 02 | tap **Month** | grid appears; 16 Aug (today) ringed **and** selected; `80k`/`145k`/`45k`/`30k` in four weights; 19–24 Jul + 25–29 Aug greyed; day section `TODAY · Rp 0` + "No expenses today" |
| 03 | tap **2 Aug** | coral fill moves to 2 Aug, ring stays on 16; header `SUN, 2 AUGUST · Rp 145.000` reconciles with the cell's `145k` |
| 04 | tap the **Dinner** card | editor opens on the right expense: Rp 120.000, 2 Aug 2026 20.30, Makan / GoPay / Fadil, Tarisa |
| 05 | commit + return | back on the calendar with **2 Aug still selected**; hero total unchanged |
| 06 | tap **‹** | July cycle `25/06 ~ 24/07`, hero `Rp 25.000`, grid repaints to 5 rows, **20 Jul now in-cycle showing `25k`**, selection re-defaults to it (latest spending day, today not in cycle); `‹` correctly disables |
| 07 | tap **›** | August cycle restored, 2 Aug still selected |
| 08 | tap **List** | day-grouped list back, identical to step 01 |
| 09 | Month → tap **13 Aug** (empty, in-cycle) | `THU, 13 AUGUST · Rp 0` + "No expenses on Thu, 13 August" |
| 10 | tap **25 Aug** (greyed filler) | inert — selection stays on 13 Aug, as `disabled(!day.inCycle)` intends |

Step 02 also caught a copy bug a static shot would have shown but the flow made obvious:
the empty-day message read "No expenses **on Today**". Added `dayPhrase` → "today" /
"yesterday" / "on Thu, 13 August".

### Tooling — `scripts/simdrive.sh` mapping fix
Every tap was silently no-op'ing at first, including on `‹`, a control that predates this
feature. Cause: `read_mapping` assumed a 28pt title bar and derived the scale from it, which
on this Simulator build put taps ~28pt too high — enough to miss any small control. This is
almost certainly the same "title-bar y-offset / first-tap swallow" flakiness recorded in
`person-expenses`' STATUS.

Fixed at the source: `read_mapping` now reads the device screen's **AXGroup** position and
size from the accessibility API — that rect *is* the on-screen device, no guessing — and
validates it by aspect ratio, falling back to the old estimate only if it can't be read.
Mapping went from `origin=(245.3, 78.0) scale=0.34363` (wrong) to
`origin=(261.0, 129.0) scale=0.31758` (exact). Taps have been reliable since.

Still true: **issue one tap at a time.** A doubled tap opened the editor and immediately
dismissed it, which reads as "nothing happened."

## Notes / open questions
- Source: user asked for "a calendar view in the Expenses tab to see my expenses based on that."
- Guardrail tension resolved at gate 0: grid is **cycle-aligned**, not month-aligned, so the
  pay-cycle model from `.scratch/revamp/spec.md` stays intact and the grid range always matches
  the hero total's range.
- Money-format guardrail: the cell's `145k` is an abbreviation, not a money string. Every
  authoritative figure beside it (day header, rows, VoiceOver label) still uses `formattedIDR()`.
- Seed data was **not** changed: it already covered 4 intensity buckets, a two-expense day
  (2 Aug = 145.000), an empty selected day (today) and an out-of-cycle expense (20 Jul).
- Not verified by automation: VoiceOver labels and accessibility-size Dynamic Type (the cell
  drops the total and bolds the date). Both are implemented and inspected in code, but neither
  was exercised in the simulator — worth a manual pass if you care about them.
- The iPad shot ran on a device whose stored Monthly Start Date is 1, so its cycle reads
  01/08 ~ 31/08 and Rp220.000. Not a bug — different device, different setting.
