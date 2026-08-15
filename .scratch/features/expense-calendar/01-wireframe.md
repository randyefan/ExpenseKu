# 01 — Wireframe · expense-calendar

Low-fidelity ASCII wireframes for every screen and state. "Warm Cards" language, 3-tab shell,
pay-cycle model intact. No code.

Grounded on the real Expenses home (`.scratch/revamp/shots/home.png`) with the seeded cycle
**August 2026 · 25/07/2026 ~ 24/08/2026 · Rp275.000**, made of:
28 Jul Rp80.000 · 2 Aug Rp120.000 · 5 Aug Rp45.000 · 6 Aug Rp30.000. Today = Sun 16 Aug.

## Notation

> **Revised 2026-08-16 (during stage 3, at the owner's request):** the cell now prints the
> day's **total** under the date instead of an intensity dot. A ~48pt column can't hold
> "Rp145.000", so it is abbreviated to thousands. The intensity ramp moved from dot *size*
> to the number's *weight + tone*.

```
 145k  bold, Theme.text        (28)  day outside the pay cycle — greyed, not tappable
  80k  semibold, Theme.text    ⟨16⟩ today — hairline ring around the number
  45k  medium, secondary       ▓16▓ selected day — coral filled circle, white number
  30k  regular, secondary      (blank under a number = no expenses that day)
```
**Weight + tone** carry the intensity, so meaning never rests on color alone (guardrail),
and the exact figure is now readable without tapping.
Every cell's VoiceOver label is still the full amount: "Thursday 6 August, Rp30.000,
1 expense" / "…, no expenses".

---

## Screen: Expenses tab — the toggle (shared by both variants)

The toggle is a segmented pill sitting between the hero card and the content. The
top-left toolbar slot keeps its existing meaning (Monthly Start Date settings) and the
top-right keeps +. Nothing in the header moves.

```
┌───────────────────────────────────────┐
│  ▣                              ( + ) │   ▣ = Monthly Start Date (unchanged)
│                                       │
│ ┌───────────────────────────────────┐ │
│ │  ‹        August 2026          ›  │ │
│ │       25/07/2026 ~ 24/08/2026     │ │   hero card: unchanged
│ │                                   │ │
│ │             SPENDING              │ │
│ │           Rp275.000               │ │   coral hero total, unchanged
│ └───────────────────────────────────┘ │
│                                       │
│          ┌─────────┬─────────┐        │
│          │  ☰ List │ ▦ Month │        │   ← NEW: segmented toggle, centered
│          └─────────┴─────────┘        │      active segment = coral (Warm Cards
│                                       │      "selected state" token)
│  … content: list  OR  calendar …      │
└───────────────────────────────────────┘
```
Controls:
- `☰ List` → the existing day-grouped list. **Default on launch.**
- `▦ Month` → the calendar grid. Choice is remembered for the session.
- `‹` `›` → unchanged; they page the pay cycle and the grid follows.
- `+` → unchanged; opens the new-expense sheet.

---

## VARIANT A — grid + selected-day list inline  *(recommended)*

The grid is a card; under it, the selected day's expenses render as the same expense cards
used by the list view. On switching to Month, the app pre-selects **today** if today is in
the cycle, otherwise the cycle's most recent day that has spending.

### A · default state (today selected, today is empty)
```
┌───────────────────────────────────────┐
│ ┌── hero card: August 2026 · Rp275.000│
│          ┌─────────┬─────────┐        │
│          │  ☰ List │▓▦ Month▓│        │
│          └─────────┴─────────┘        │
│ ┌───────────────────────────────────┐ │
│ │   S    M    T    W    T    F    S │ │  ← weekday header, secondary text
│ │                                   │ │
│ │ (19) (20) (21) (22) (23) (24)  25 │ │  greyed: before the cycle starts
│ │                                   │ │
│ │  26   27   28   29   30   31    1 │ │
│ │            80k                    │ │  28 Jul · Rp80.000 — semibold
│ │                                   │ │
│ │   2    3    4    5    6    7    8 │ │
│ │  145k             45k  30k        │ │  2 Aug bold · 5 Aug medium · 6 Aug regular
│ │                                   │ │
│ │   9   10   11   12   13   14   15 │ │
│ │                                   │ │
│ │                                   │ │
│ │ ▓16▓  17   18   19   20   21   22 │ │  today, selected (coral fill), no spend
│ │                                   │ │
│ │                                   │ │
│ │  23   24  (25) (26) (27) (28) (29)│ │  greyed: after the cycle ends
│ └───────────────────────────────────┘ │
│                                       │
│  TODAY                     Rp0        │  ← day header, same style as list
│                                       │     view's day header (secondary,
│  ┌───────────────────────────────────┐│     mono total, never coral)
│  │      No expenses on Sun, 16 Aug   ││
│  │        Tap + to log one.          ││
│  └───────────────────────────────────┘│
│                                       │
│      ☰ Expenses   ◔ Insights   ▤ Manage│
└───────────────────────────────────────┘
```
Controls:
- tap any in-cycle day → selects it; the section below swaps to that day.
- tap a greyed day → nothing (not a hit target); paging with `‹ ›` is how you leave the cycle.

### A · a day with expenses selected (tapped 2 Aug)
```
│ │   2    3    4    5    6    7    8 │ │
│ │  ▓2▓             •    ·           │ │  ← selected + it is the heavy day
│ …                                     │
│  SUN, 2 AUGUST              Rp120.000 │
│                                       │
│  ┌───────────────────────────────────┐│
│  │ (🍴) Makan                        ││  same ExpenseRow card as the list
│  │      Dinner          Rp 120.000   ││  view — icon chip, title, merchant,
│  │      ▤ GoPay                      ││  account, companions, mono amount
│  │      ⧑ Fadil and Tarisa           ││
│  └───────────────────────────────────┘│
│                                       │
│  ‹ swipe a row left to delete ›       │  swipe-to-delete preserved
└───────────────────────────────────────┘
```
Controls:
- tap an expense card → opens the editor (sheet on iPhone, detail pane on iPad/Mac) — same
  behaviour as the list view.
- swipe a card → delete, same as the list view.

### A · a day with several expenses (scroll)
```
│  TUE, 28 JULY                Rp80.000 │
│  ┌───────────────────────────────────┐│
│  │ (🚗) Transport  Grab   Rp 50.000  ││
│  └───────────────────────────────────┘│
│  ┌───────────────────────────────────┐│
│  │ (🍴) Makan      Kopi   Rp 30.000  ││   newest time first (existing rule)
│  └───────────────────────────────────┘│
│         ⋮ page scrolls; grid scrolls   │
│           away above the day list      │
```

---

## VARIANT B — grid + day sheet

Grid gets the whole screen (bigger cells, roomier dots). Nothing is selected by default;
tapping a day raises a bottom sheet.

### B · default state (nothing selected)
```
┌───────────────────────────────────────┐
│ ┌── hero card: August 2026 · Rp275.000│
│          ┌─────────┬─────────┐        │
│          │  ☰ List │▓▦ Month▓│        │
│          └─────────┴─────────┘        │
│ ┌───────────────────────────────────┐ │
│ │    S    M    T    W    T    F   S │ │
│ │                                   │ │
│ │  (19) (20) (21) (22) (23) (24) 25 │ │
│ │                                   │ │
│ │   26   27   28   29   30   31   1 │ │
│ │             ●                     │ │
│ │                                   │ │
│ │    2    3    4    5    6    7   8 │ │   cells ~1.5× taller than Variant A
│ │    ⬤              •    ·          │ │
│ │                                   │ │
│ │    9   10   11   12   13   14  15 │ │
│ │                                   │ │
│ │                                   │ │
│ │  ⟨16⟩  17   18   19   20   21  22 │ │   today ringed but NOT selected
│ │                                   │ │
│ │                                   │ │
│ │   23   24  (25) (26) (27) (28)(29)│ │
│ └───────────────────────────────────┘ │
│                                       │
│      Tap a day to see its expenses    │   quiet hint, secondary text
│                                       │
│      ☰ Expenses   ◔ Insights   ▤ Manage│
└───────────────────────────────────────┘
```

### B · day sheet raised (tapped 2 Aug)
```
│ │    2    3    4    5    6    7   8 │ │
│ │   ▓2▓             •    ·          │ │
├───────────────────────────────────────┤
│                 ▁▁▁▁                  │  drag indicator
│  Sun, 2 August              Rp120.000 │
│                                       │
│  ┌───────────────────────────────────┐│
│  │ (🍴) Makan                        ││
│  │      Dinner          Rp 120.000   ││
│  │      ▤ GoPay                      ││
│  │      ⧑ Fadil and Tarisa           ││
│  └───────────────────────────────────┘│
│                                       │
└───────────────────────────────────────┘
   medium detent. Swipe down to dismiss.
   Tapping another day swaps the sheet's contents.
```
Trade-off: bigger grid, but tapping an expense means a **sheet on top of a sheet** to reach
the editor, and the grid is half-covered while browsing days.

---

## Shared states (both variants)

### Empty cycle — grid renders, message replaces the day section
```
│          ┌─────────┬─────────┐        │
│          │  ☰ List │▓▦ Month▓│        │
│          └─────────┴─────────┘        │
│ ┌───────────────────────────────────┐ │
│ │   S    M    T    W    T    F    S │ │
│ │ (26) (27) (28) (29) (30)   1    2 │ │
│ │                                   │ │   grid still drawn, all dots absent
│ │   3    4    5    6    7    8    9 │ │
│ │                     ⋮             │ │
│ └───────────────────────────────────┘ │
│                                       │
│         🗓  No expenses this cycle     │
│      Nothing logged for               │
│      25/09/2026 ~ 24/10/2026.         │
└───────────────────────────────────────┘
```

### First run — no expenses anywhere
Same as today's list-view first-run state, kept verbatim:
```
│            📄  No expenses yet         │
│         Tap + to log your first        │
│                expense.                │
```
The toggle stays visible so the calendar is still discoverable.

### Dark mode
Same layout. `bg #17130F`, grid card `#211C1A`, weekday header + greyed dates
`textSecondary #A79E98`, dots + selected fill coral `#E8735C`, selected day's number
inverts to the card color.

### Large Dynamic Type
Cells keep a fixed 7-across grid (a calendar that reflows isn't a calendar). The date
number scales; at **accessibility** sizes there is no room for a second line, so the cell
drops the printed total and marks a spending day with a bold date instead. The VoiceOver
label still carries the exact amount, so nothing is lost to a screen-reader user.

### iPad / Mac (split view)
The grid lives in the **sidebar** column exactly like the list does today; the selected
day's expenses render under it (Variant A) and the editor stays in the detail pane. No
change to the split behaviour.

---

## Flow

```
Expenses tab (List, default)
      │  tap ▦ Month
      ▼
Calendar view ──tap a day──▶ day's expenses ──tap a row──▶ Expense editor
      │                                                        │ save/cancel
      │  ‹ ›  page cycle → grid + hero total both follow       ▼
      │  tap ☰ List → back to the day-grouped list       back to calendar
      ▼
   (+ always available → new expense sheet)
```

Entry point: the Expenses tab itself. Nothing else in the app links here, and no existing
screen changes except the addition of the toggle row.

---
Gate 1: show these via AskUserQuestion (one variant per preview) and loop until the user
agrees on the UX. Then advance to the tech spec.
