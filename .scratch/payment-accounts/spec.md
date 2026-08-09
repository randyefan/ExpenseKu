# Spec: Payment Account tracking

Status: ready-for-agent

Track which **account / payment method** each expense was paid from (Cash, a bank,
an e-wallet). A **label only** — no balances, income, or transfers. Mirrors the
existing `Category`/`Person` tag-entities and their patterns.

See `CONTEXT.md` (repo root) for the ubiquitous language and `docs/adr/` for the
delete-semantics (ADR-0001) and de-dup (ADR-0002) decisions this reuses.

## Data model

- New `Account` SwiftData entity:
  - `name: String = ""`, `colorHex: String?`
  - `@Relationship(deleteRule: .nullify, inverse: \Expense.account) expenses: [Expense]?`
  - Conforms to `NamedEntity` (reuses `existingEntity` de-dup + `NameEditorView`).
- `Expense` gains `account: Account?` — **optional**, single-select to-one.
- CloudKit-safe: name defaulted; `colorHex` + relationship optional; no unique constraint.

## Behavior

- **Optional at entry** (unlike required Category). No backfill for existing expenses.
- **Delete = nullify** (ADR-0001): deleting an Account leaves its expenses "Unassigned"; never cascade.
- **De-dup = prompt** (ADR-0002): case-insensitive name match prompts, via `NameEditorView`.

## UI

- Add-expense editor: new **Account** row directly under Category (same section),
  single-select via a new `AccountPicker` (cloned from `CategoryPicker`, pops on select).
- Manage tab: third row — Categories · People · **Accounts** — with an Accounts CRUD screen.
- Expense row surfaces the account where it fits.

## Analytics

- **Spend-by-Account** chart in Insights, beside the other charts, under the shared Period
  filter; expenses with no account roll into an "Unassigned" bucket. New `SpendSummary.byAccount`.
- **Account filter** on the People leaderboard (next to Category + Period). `PeopleLeaderboard.ranked`
  gains an optional `account:` parameter.

## Out of scope

Balances, opening balances, income/top-ups, transfers, reconciliation, multi-currency.

## Tickets

1. `01` Account model + Expense.account + glossary
2. `02` Manage Accounts screen + AccountPicker
3. `03` Account in the expense editor + row
4. `04` Spend-by-Account chart
5. `05` Account filter on the People leaderboard
6. `06` Unit tests for account analytics

## Comments
