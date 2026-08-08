# 03 — Data models: Expense, Category, Person

Status: resolved

Implement the SwiftData `@Model` types per the design from ticket 01.

## Scope

- **Expense**: `amount: Decimal`, `date: Date`, `note: String`, to-one `category`, many-to-many `people`.
- **Category**: `name` (+ optional color/icon), inverse relationship to Expense.
- **Person**: `name`, many-to-many with Expense.
- All properties optional-or-defaulted; relationships optional (CloudKit constraint).
- Delete semantics implemented per ticket 01's decision.

## Definition of done

- Models compile and persist; relationships resolve both directions.
- Money is `Decimal` throughout — no `Double` anywhere in the money path.

## Comments

- 2026-08-09: Implemented `Expense`, `Category`, `Person` under `ExpenseKu/ExpenseKu/Models/` per design.md §3. Money is `Decimal`; all attributes defaulted, relationships optional (CloudKit-safe). Delete rules set to `.nullify` on Category/Person inverses (ADR-0001). Removed throwaway `Item`; app schema + placeholder ContentView updated. Verified with `xcodebuild ... -destination 'iOS Simulator,iPhone 17 Pro'` → **BUILD SUCCEEDED**. Runtime persist/sync will be exercised by tickets 05/06 + the ticket-02 CloudKit wizard.
