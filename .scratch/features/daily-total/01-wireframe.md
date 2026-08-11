# 01 — Wireframe · daily-total

Low-fidelity ASCII wireframes. Stay in "Warm Cards" + the 3-tab shell. No code.
The only change is the **day section header**: today it shows just the day title on the
left; we add that day's total on the trailing edge. Rows and the cycle hero are unchanged.

## Screen: Expenses list — default state (Variant A · subtle, header-styled total)
```
┌────────────────────────────────────────┐
│  ‹        August 2026        ›          │
│         Aug 1 – Aug 31                  │
│                                        │
│            SPENDING                     │
│           Rp 1.240.000     (coral)      │
├────────────────────────────────────────┤
│  TODAY                    RP 320.000    │  ← header: title left, total right
│  ┌──────────────────────────────────┐  │     (caption, uppercased, secondary)
│  │ 🍜  Lunch            Rp 45.000   │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ ⛽  Fuel            Rp 275.000   │  │
│  └──────────────────────────────────┘  │
│                                        │
│  YESTERDAY                RP 180.000    │
│  ┌──────────────────────────────────┐  │
│  │ ☕  Coffee           Rp 30.000   │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ 🛒  Groceries       Rp 150.000   │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```
Controls:
- Day header total → read-only. Sum of that day's expense amounts, current cycle only.
- Matches `SectionHeaderText` styling (dsCaption, semibold, secondary, uppercased,
  monospaced digits) so it reads as a quiet label, not competing with the coral hero.

## Screen: Expenses list — default state (Variant B · prominent, body-weight total)
```
┌────────────────────────────────────────┐
│            SPENDING                     │
│           Rp 1.240.000     (coral)      │
├────────────────────────────────────────┤
│  TODAY                     Rp 320.000   │  ← title caption (secondary) +
│  ┌──────────────────────────────────┐  │     total body weight, primary text
│  │ 🍜  Lunch            Rp 45.000   │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ ⛽  Fuel            Rp 275.000   │  │
│  └──────────────────────────────────┘  │
│                                        │
│  YESTERDAY                 Rp 180.000   │
│  ...                                    │
└────────────────────────────────────────┘
```
Controls:
- Same data as A, but the total uses `MoneyText` (dsBody, bold, primary `Theme.text`) so
  it stands out more against the day rows. Title stays caption/secondary.

## Screen: Expenses list — empty states (unchanged)
```
No expenses anywhere:            This cycle empty:
┌──────────────────────┐        ┌──────────────────────┐
│   (doc.text icon)    │        │   (calendar icon)    │
│   No expenses yet    │        │  No expenses this    │
│  Tap + to log your   │        │       cycle          │
│    first expense.    │        │ Nothing logged for … │
└──────────────────────┘        └──────────────────────┘
```
- No day headers render, so no total shows. Empty states are untouched by this feature.

## Flow
Expenses tab → day-grouped `List`. The total is computed per `DayGroup` and rendered inside
the existing section `header:`. No new screen, navigation, or entry point. Add/edit/delete an
expense → the affected day's total recomputes with the list (SwiftData `@Query` re-render).

---
Gate 1: show A vs B via AskUserQuestion previews; loop until the user agrees on the UX.
