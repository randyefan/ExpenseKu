# 01 — Account model + Expense.account + glossary

Status: resolved

Add the `Account` entity and wire it to `Expense`. See `../spec.md`.

## Scope

- New `Account` `@Model` under `ExpenseKu/ExpenseKu/Models/`:
  - `name: String = ""`, `colorHex: String?`
  - `@Relationship(deleteRule: .nullify, inverse: \Expense.account) expenses: [Expense]?`
- `Expense` gains `account: Account?` (optional; update the initializer).
- Extend `Account: NamedEntity` in `Shared/NamedEntity.swift`.
- Add `Account.self` to the `Schema` in `ExpenseKuApp` and to test/in-memory containers.
- Update `CONTEXT.md`: add the **Account** glossary term ("reusable, owner-defined payment
  source; optional on an Expense; 'Unassigned' when absent; not a balance-bearing ledger").

## Definition of done

- Builds on the iOS 17 simulator; relationships resolve both directions.
- No `Double` in the money path (unchanged); all Account properties CloudKit-safe.

## Comments

Resolved — implemented and verified: full test build succeeds on the iOS simulator (iPhone 17 Pro) and all 16 unit tests pass (incl. 6 new AccountAnalyticsTests).
