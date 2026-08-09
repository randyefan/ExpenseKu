# ExpenseKu

A personal, single-user expense tracker — a native Apple app (iOS / iPadOS / macOS)
built with **SwiftUI + SwiftData**, synced privately across the owner's devices via
**CloudKit**. No accounts, no sharing, no backend.

## Features

- **Log expenses fast** — amount, note, one Category, an optional Account (payment
  source), and any number of People (companions you were with).
- **Pay-cycle home** — the Expenses screen is framed by your **pay cycle**, not the
  calendar month: one cycle at a time anchored to a configurable **Monthly Start Date**,
  paged with `‹ ›`, titled by the month it ends in, with a per-cycle spending total and
  day-by-day grouping.
- **Insights** — spend by category, spend by account, and spend over time, over a shared
  date filter that includes a **This pay period** preset.
- **People leaderboard** — ranks the People you spend the most *with* (companion
  attribution, not bill-splitting).
- **Manage** — add/rename/delete Categories, People, and Accounts.

Money is stored as `Decimal` in a single implicit currency (**IDR** for v1).

## Not in scope (v1)

Budgets/limits · recurring expenses · receipt photos · multi-currency · bank/CSV import ·
income tracking · bill-splitting · widgets/Siri/App Intents.

## Project layout

```
ExpenseKu/
  ExpenseKu/            App target (SwiftUI views, SwiftData models, analytics)
  ExpenseKuTests/       Unit tests (pure analytics + cycle math)
  ExpenseKu.xcodeproj
docs/adr/               Architecture decision records
CONTEXT.md              Ubiquitous language — the source of truth for domain terms
AGENTS.md               Conventions for agent-assisted work
```

## Build & test

Open `ExpenseKu/ExpenseKu.xcodeproj` in Xcode, or from the command line:

```sh
xcodebuild test \
  -project ExpenseKu/ExpenseKu.xcodeproj \
  -scheme ExpenseKu \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Documentation

- **[CONTEXT.md](CONTEXT.md)** — glossary and key decisions. Use these terms as defined.
- **[docs/adr/](docs/adr/)** — the "why" behind non-obvious choices (nullify-on-delete,
  app-level de-duplication, the pay-cycle model).
