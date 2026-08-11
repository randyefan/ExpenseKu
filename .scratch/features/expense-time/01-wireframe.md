# 01 — Wireframe · expense-time

Low-fidelity wireframes for the Expense editor (Add / Edit). Only the **detail rows** block
changes — the amount hero, keypad dock, note field, and navigation are untouched. Stays in
the "Warm Cards" language and the 3-tab shell. No code.

The list screen is unchanged visually; it already sorts newest-first by timestamp, so once a
time can be set the same-day order simply reflects it. No wireframe needed for the list.

---

## Variant A — one combined Date+Time row (recommended)

The existing "Date" row's picker shows date **and** time inline. One row, native, minimal.

```
  Add Expense
 ┌───────────────────────────────────────────┐
 │              Rp  25,000                     │   ← amount hero (unchanged)
 └───────────────────────────────────────────┘
 ┌───────────────────────────────────────────┐
 │  Date          Aug 11, 2026    2:30 PM  ▸   │   ← DatePicker [.date, .hourAndMinute]
 │  Category      Groceries                ›   │
 │  Account       Cash                     ›   │
 │  People        Me                       ›   │
 └───────────────────────────────────────────┘
 ┌───────────────────────────────────────────┐
 │  Add a note…                                │
 └───────────────────────────────────────────┘
      [ keypad dock — unchanged ]
```
Controls:
- `Date` row → tapping the date opens the calendar; tapping the time opens the wheel/field.
  Both edit the single stored timestamp. Default = now for a new expense; existing value
  when editing.

---

## Variant B — separate Date row + Time row

Keep "Date" date-only; add a distinct "Time" row beneath it.

```
 ┌───────────────────────────────────────────┐
 │  Date          Aug 11, 2026             ▸   │   ← DatePicker [.date]
 │  Time          2:30 PM                  ▸   │   ← DatePicker [.hourAndMinute]
 │  Category      Groceries                ›   │
 │  Account       Cash                     ›   │
 │  People        Me                       ›   │
 └───────────────────────────────────────────┘
```
Controls:
- `Date` row → calendar, day only.
- `Time` row → hour/minute wheel. Two rows bind to the same underlying `date`; the editor
  recombines day-from-Date with time-from-Time on save.

---

## States
- **Add (new):** time pre-filled to the current time; user can change it.
- **Edit (existing):** shows the expense's saved time; changing it updates the expense.
- **Empty / error:** none new — time always has a value (a `Date` can't be blank), so there's
  no empty or invalid-time state. Save logic (required Category/amount) is unchanged.

## Flow
Expenses tab → tap `+` (Add) or tap a row (Edit) → editor with the Date/Time control →
Save. Same entry/exit as today; only the detail-rows block gains time input.

---
Gate 1: show these via AskUserQuestion (one variant per preview) and loop until the user
agrees on the UX. Then advance to the tech spec.
