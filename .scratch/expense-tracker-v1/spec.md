# Spec: ExpenseTracker v1

Status: ready-for-agent

The core logging loop for a personal, single-user expense tracker: record expenses, tag them with a category and companions, and see basic analytics — including "who did I spend the most with."

See `CONTEXT.md` at the repo root for the ubiquitous language this spec uses.

## Goals

- Log an expense in seconds on iPhone at the point of purchase.
- Review and analyze on iPad/Mac.
- Data syncs privately across all the owner's Apple devices, no backend.

## Platform & stack

- Native Apple: **iOS, iPadOS, macOS**.
- **SwiftUI**, single **multiplatform target**, adaptive layouts per device.
- OS floor: **iOS 17 / iPadOS 17 / macOS 14**.
- Persistence: **SwiftData** with **CloudKit** private-database mirroring.
- Accepted SwiftData+CloudKit constraints: all properties optional-or-defaulted; no unique constraints.

## Data model

### Expense
- `amount`: `Decimal` — single implicit currency (IDR), no currency field in v1.
- `date`: `Date` (date + time) — defaults to now at entry; UI surfaces date only.
- `note`: `String`.
- `category`: to-one → **Category**.
- `people`: many-to-many → **Person** (companions).

### Category
- `name`: `String` (+ optional color/icon).
- To-one from Expense (one Category, many Expenses).
- Owner can add/rename without a rebuild.

### Person
- `name`: `String`.
- Many-to-many with Expense.
- Semantics: **companion the owner was with**, not a beneficiary. No bill-splitting.

## Features (v1)

1. **Create / edit / delete an Expense**
   - Fields: amount, date (defaults now), category (pick from existing or create), people (pick zero+ from existing or create), note.
   - Category and Person are **selected from existing entries or created inline** — never free-typed into the expense as a raw string (de-dup is a UI responsibility; SwiftData+CloudKit enforces no uniqueness).

2. **Expense list**
   - Chronological list of expenses, showing amount, date, category, and tagged people.

3. **Manage Categories and People**
   - Add, rename, delete. Deleting is allowed; define behavior for expenses referencing a deleted Category/Person (e.g. leave nil / uncategorized).

4. **Analytics**
   - **Spend by category** — chart.
   - **Spend over time** — chart.
   - **People leaderboard** — ranked list of Person → total attributed spend + count of shared expenses.
     - Attribution: **full amount to each companion** (query-time; nothing stored). A 100k expense with 2 people credits 100k to each.
     - **Filterable by category and date range** (e.g. "top people for Makan this month").

## Non-goals (deferred beyond v1)

Budgets/limits · recurring expenses · receipt photos · multi-currency · bank/CSV import · income tracking · bill-splitting/beneficiary tracking · widgets/Siri/App Intents.

## Open edges (tracked, not blocking)

- **Person/Category de-duplication** — must be prevented in the UI (pick-from-existing) since CloudKit disallows unique constraints. Two "Fadil" records would silently corrupt the leaderboard.
- **Delete semantics** — decide what happens to expenses when a referenced Category or Person is deleted.
- **Multi-currency** — the `Decimal`-without-currency-field choice makes this a future migration, not a free addition.

## Comments
