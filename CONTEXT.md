# ExpenseTracker — Context

Personal, single-user expense tracker. Native Apple app (iOS / iPadOS / macOS) built with SwiftUI + SwiftData, synced privately across the owner's devices via CloudKit. No accounts, no sharing, no backend.

This document is the source of truth for the project's **ubiquitous language**. When code, issues, or specs name a concept below, use the term as defined here — don't drift to synonyms.

## Glossary

- **Expense** — a single record of money the owner spent. Carries an amount, a timestamp, a note, exactly one Category, and zero or more People.
- **Amount** — the money value of an Expense, stored as `Decimal` in a single implicit currency (**IDR** for v1). There is no per-expense currency field yet; multi-currency is a future migration.
- **Category** — a reusable, owner-defined label for *what kind* of spend an Expense is (e.g. "Makan"). A first-class entity so it can be added or renamed without a rebuild. An Expense has exactly one, **required at entry**. (The stored property is optional for CloudKit's sake and may become nil only via category deletion — see **Uncategorized**.)
- **Uncategorized** — the display state of an Expense whose Category was deleted (`category = nil`). A valid state for *existing* expenses only; new expenses always require a Category.
- **Person** — a reusable entity naming a **companion** the owner was *with* when spending. An Expense can be tagged with many People; a Person appears across many Expenses (many-to-many).
  - A Person is **who I was with**, *not* who I paid on behalf of. There is no bill-splitting or beneficiary tracking.
- **Companion** — synonym for Person in prose; the People tagged on an Expense.
- **Account** — a reusable, owner-defined **payment source** an Expense was paid from (e.g. "Cash", "GoPay", a bank). A first-class tag-entity like Category, but **optional** on an Expense and single-select. It is a **label only** — *not* a balance-bearing ledger: no balances, income, top-ups, transfers, or reconciliation. Deleting an Account nullifies it on its expenses (ADR-0001), leaving them **Unassigned**.
- **Unassigned** — the display state of an Expense with no Account (`account = nil`), whether never set (accounts are optional at entry) or left behind by Account deletion. The Account analogue of **Uncategorized**.
- **Spend attribution** — how an Expense's amount is credited to its People for ranking. Rule: **full amount to each companion**. A 100k Expense tagged with two People counts 100k toward *each*. This is a per-person ranking, not a sum, so totals can exceed the grand total by design. Attribution is computed at query time; nothing extra is stored.
- **People leaderboard** — the analytics view ranking People by total attributed spend, with a count of shared Expenses, filterable by Category and date range. This is the feature that answers "who did I spend the most with."

## Key decisions

- **Single-user, no auth.** Data is private to the owner's Apple ID via CloudKit; there is no server to run.
- **SwiftData + CloudKit constraints are accepted.** All model properties are optional-or-defaulted and there are **no enforced unique constraints**. Consequence: de-duplication of Category and Person is a **UI concern** — always pick from existing, and prompt on a case-insensitive name match rather than creating a duplicate (**ADR-0002**).
- **Deletes nullify, never cascade** (**ADR-0001**). Deleting a Category leaves its expenses **Uncategorized**; deleting a Person removes them from expenses; deleting an Account leaves its expenses **Unassigned**. Expenses are never destroyed by deleting a tag.
- **Money is `Decimal`, never `Double`.** Avoids floating-point drift in totals.
- **Timestamps store date + time**, default to now at entry; only the date is surfaced in the v1 UI.

## Out of scope (v1)

Budgets/limits · recurring expenses · receipt photos · multi-currency · bank/CSV import · income tracking · bill-splitting/beneficiary tracking · widgets/Siri/App Intents.

See `.scratch/expense-tracker-v1/spec.md` for the full v1 specification and `.scratch/expense-tracker-v1/design.md` for the accepted design. ADRs live in `docs/adr/`.
