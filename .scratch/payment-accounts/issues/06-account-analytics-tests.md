# 06 — Unit tests for account analytics

Status: ready-for-agent
Blocked by: 04, 05

Cover the new pure aggregations in `ExpenseKuTests`, following the existing pattern
(un-inserted model objects, no ModelContext; `private typealias Category = ExpenseKu.Category`
and likewise for `Account` if the name is ambiguous under `@testable import`).

## Scope

- `SpendSummary.byAccount`: totals per account, the **"Unassigned"** bucket for nil-account
  expenses, sort order, and the date-range filter.
- `PeopleLeaderboard.ranked(account:)`: the account filter restricts the ranking; combined
  with the category filter behaves as expected.

## Definition of done

- New tests pass via `xcodebuild test` on the iOS 17 simulator; existing tests stay green.

## Comments
