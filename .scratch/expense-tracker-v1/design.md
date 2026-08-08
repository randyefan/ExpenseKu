# ExpenseTracker v1 — Design

Output of ticket 01. Accepted by the owner. Tickets 02–08 build against this.
See `spec.md` for scope and `CONTEXT.md` (repo root) for the ubiquitous language.

## 1. Navigation & screen map

**iPhone** — `TabView`, three tabs:
- **Expenses** — reverse-chronological list + floating **+** to log. The home surface.
- **Insights** — Spend-by-Category, Spend-over-Time, People Leaderboard.
- **Manage** — Categories and People (two sections/subscreens under one tab).

**iPad / Mac** — `NavigationSplitView` with a sidebar (Expenses · Insights · Categories · People) and a detail pane. The expense list uses **list + detail**: selecting a row edits it in the detail pane. On iPhone, editing is a sheet.

Screens: Expense List · Add/Edit Expense (sheet) · Insights · Manage Categories · Manage People.

## 2. Add-expense flow (fastest path, iPhone)

Floating **+** → **sheet** with the **amount field auto-focused on the number pad**. Date pre-filled to *now* (collapsed; tap to change). Category = **required**, chosen from a horizontal **chip row** (or "＋ New"). People = optional **multi-select chips** (or "＋ New"). Note = optional. **Save** top-right, enabled once amount > 0 and a category is set.

Inline category/person creation routes through the de-dup check in §5.

## 3. SwiftData schema

```swift
@Model
final class Expense {
    var amount: Decimal = 0
    var date: Date = Date.now
    var note: String = ""
    var category: Category?            // optional per CloudKit; UI requires it at entry
    var people: [Person]? = []         // many-to-many, optional
    init() {}
}

@Model
final class Category {
    var name: String = ""
    var colorHex: String?             // optional color for charts
    @Relationship(inverse: \Expense.category)
    var expenses: [Expense]? = []
    init() {}
}

@Model
final class Person {
    var name: String = ""
    @Relationship(inverse: \Expense.people)
    var expenses: [Expense]? = []
    init() {}
}
```

All properties defaulted, all relationships optional, no `.unique` — the SwiftData+CloudKit tax. `category` is optional in the schema (CloudKit requires it) but **required by the UI at entry**; it can only become `nil` later via category deletion (§5).

## 4. Module / file structure

```
ExpenseTracker/
├── App/            — App entry, ModelContainer + CloudKit config
├── Models/         — Expense, Category, Person
├── Features/
│   ├── Expenses/   — list, editor sheet, row
│   ├── Categories/ — manage screen
│   ├── People/     — manage screen
│   └── Insights/   — charts + leaderboard views
├── Analytics/      — pure query/aggregation layer (UI-free, unit-testable)
└── Shared/         — CategoryPicker, PeoplePicker, money/IDR formatter, chips
```

`Analytics/` is deliberately SwiftUI-free so spend attribution and the leaderboard are unit-testable without a view.

## 5. Resolved decisions

### Category is required at entry
Every expense must have a category when saved (drives the primary chart). See §3 for why the stored property is still optional. → ADR-0001 context.

### Delete semantics — nullify, never cascade  (ADR-0001)
- Delete a **Category** → affected expenses show **"Uncategorized"** (`category = nil`). Expenses are never deleted.
- Delete a **Person** → removed from each expense's `people`; expenses stay.
- Rationale: historical spend is the source of truth; deleting a tag must not erase money records.

### De-dup — prompt on near-duplicate  (ADR-0002)
- Category/Person are **never free-typed onto an expense** — always pick from existing or "＋ New".
- On "＋ New", query existing by **trimmed, case-insensitive** name. On a match, **prompt** the owner ("Use existing 'Fadil'?") rather than silently reusing or blindly creating. This is the app-level guard replacing the unique constraint CloudKit won't enforce.

## 6. Cross-cutting notes

- **Money**: `Decimal` end to end, formatted for **IDR** via a shared formatter in `Shared/`. No `Double` in the money path.
- **Attribution** (leaderboard): full amount to each companion, computed at query time in `Analytics/`. Nothing extra stored.
