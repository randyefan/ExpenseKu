# 03 — Data models: Expense, Category, Person

Status: needs-info
Blocked by: 01, 02

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
