# 03 — Account in the expense editor + row

Status: resolved
Blocked by: 01, 02

Let the owner set an account when logging an expense, and surface it in the list.

## Scope

- `ExpenseEditorView`: add an **Account** row directly under Category (same section),
  optional, using `AccountPicker`. Bind to a new `@State account: Account?`; persist on save.
- `ExpenseRow`: surface the account label where it fits (e.g. alongside date/people),
  kept subtle since it's optional.

## Definition of done

- Logging/editing an expense can set or clear its account; the value round-trips.
- Builds on the iOS 17 simulator.

## Comments

Resolved — implemented and verified: full test build succeeds on the iOS simulator (iPhone 17 Pro) and all 16 unit tests pass (incl. 6 new AccountAnalyticsTests).
