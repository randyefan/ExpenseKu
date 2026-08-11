# 02 — Tech spec · daily-total

Approved UX: **Variant A** — day's total on the trailing edge of the existing day-section
header, styled like the header label (quiet, secondary, monospaced digits).

## Data model
None. No new/changed `@Model`, no migration. Reuses `Expense.amount` (Decimal) and the
existing calendar-day grouping.

## Approach
Put the sum in the **pure, testable** grouping file so the behaviour has a unit oracle:

- `ExpenseDayGroup` gains a computed `total: Decimal` = sum of `expenses.map(\.amount)`.
  (Computed, not stored — `expenses` is already the day's set, so no risk of drift.)
- `ExpensesView.DayGroup` gains a `total: Decimal`, populated from `group.total` in the
  `dayGroups` mapping.
- The section `header:` becomes an `HStack`: `SectionHeaderText(group.title)` on the lead,
  `Spacer()`, and the total on the trailing edge — same visual weight as the header label
  (dsCaption, semibold, `Theme.textSecondary`, uppercased-style, `.monospacedDigit()`).
  Rendered inline (not `MoneyText`, which is bold/body) to match Variant A exactly.

## Files touched
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseDayGrouping.swift` (edit) — add
  `var total: Decimal` to `ExpenseDayGroup`.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpensesView.swift` (edit) — add `total` to the
  private `DayGroup`, populate it, render it in the section header HStack.
- `ExpenseKu/ExpenseKuTests/ExpenseDayGroupingTests.swift` (edit) — add total tests.

## Control surface (so the screen is screenshot-able)
No new hook needed — the day-grouped list is already reachable:
`scripts/shot.sh daily-total -- -seedSampleData -startTab expenses` (and `-a` for dark).

## Fixtures
`DebugLaunch.seedIfNeeded` already seeds two Aug-2 expenses (08:15 / 20:30) plus other
days, so multiple day groups render with multi-expense day totals. Verify the seeded data
lands in the *current* pay cycle so the shot shows populated day headers; if the shot shows
an empty cycle, page/adjust seed dates so at least two days with 2+ expenses each are in the
visible cycle. No new fixture expected.

## Test plan (behaviour oracle) — write first in stage 3
- [ ] `testDayTotalSumsAmounts` — a day with 25_000 + 120_000 → `total == 145_000`.
- [ ] `testDayTotalsPerGroupAreIndependent` — two days return each day's own sum, not a
      running/global total.
- [ ] `testSingleExpenseDayTotalEqualsItsAmount` — one-expense day → total == that amount.
- [ ] (existing grouping/sort tests stay green.)

## Risks / guardrails touched
- Money format guardrail: use the same IDR formatting (`Decimal.formattedIDR()` /
  monospaced digits) — do not invent a new format.
- Coral-accent guardrail: coral stays reserved for the cycle hero; the day total is
  `Theme.textSecondary`, never coral.
- Layout: header row must stay single-line and not push into the row cards; trailing total
  right-aligned. Confirm in both light and dark shots.

---
Gate 2: user agrees the approach is sound before any code is written.
