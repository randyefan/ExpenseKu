# 00 — Brief · daily-total

## Problem
On the Expenses tab, expenses are grouped by day (Today / Yesterday / a dated header),
but there is no **daily total** shown anywhere — the user can see each expense's amount
and the whole-cycle "Spending" hero, but not how much was spent on a given day. To know a
day's total they have to add the rows up in their head.

## Who it's for
The owner logging day-to-day spending, scanning the list to answer "how much did I spend
today / on that day?" without opening Insights or doing mental math.

## Acceptance criteria
- [ ] Each day group in the Expenses list shows the sum of that day's expense amounts.
- [ ] The daily total uses the app's money format (IDR whole numbers, right-aligned,
      monospaced) and stays consistent with the rest of the list.
- [ ] The total reflects only the expenses in that day group of the current pay cycle,
      and updates when an expense is added, edited, or deleted.
- [ ] Empty states are unaffected (no total shown when a cycle/day has no expenses).
- [ ] Works in light + dark mode and does not break the existing layout or the cycle hero.

## Out of scope
- No change to the pay-cycle hero "Spending" total or its coral accent.
- No new totals in Insights or Manage; this is the Expenses list only.
- No per-category or per-account daily breakdown — just the day's grand total.
- No model/schema change.

---
Gate 0: user confirms "this is the feature." Do not start wireframes until approved.
