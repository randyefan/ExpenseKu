# 02 — Tech spec · person-expenses

Display-only drill-down. Zero schema change; one new pure query fn (behaviour oracle),
one new view, and a NavigationLink from the existing leaderboard row. Approved UX =
Wireframe **Variant A** (flat, newest-first).

## Data model
**None.** No new/changed SwiftData `@Model`, no fields, no migration. The feature reads
existing `Expense` / `Person` / `Category` / `Account`. Attribution rule unchanged (full
amount to each companion), so the detail total = plain sum of the listed expenses and
reconciles with the leaderboard row by construction.

## Analytics (pure, testable — the behaviour oracle lives here)
Add to `enum PeopleLeaderboard` (`Analytics/PeopleLeaderboard.swift`) a sibling to
`ranked(...)`:

```
static func expenses(
    for person: Person,
    from expenses: [Expense],
    category: Category? = nil,
    account: Account? = nil,
    dateRange: ClosedRange<Date>? = nil
) -> [Expense]
```
- Same category/account/dateRange gate as `ranked`.
- Keeps an expense iff its `people` contains `person` (compared by `persistentModelID`).
- Sorted **newest-first** by `date` descending (stable; matches Variant A).
- No "Me" special-casing needed here — we only ever navigate to a ranked companion, and
  `ranked` already excludes Me, so Me is never a destination.

Invariant the tests pin: for any filter combo, `expenses(for: p, …).count` ==
the leaderboard row's `sharedCount`, and their amount-sum == the row's `total`.

## New view
`ExpenseKu/ExpenseKu/Features/Insights/PersonExpensesView.swift` (new)
- Init: `PersonExpensesView(route: PersonExpensesRoute)` — carries the person + the three
  active filters so the screen matches the row it came from.
- `@Query private var expenses: [Expense]`; derives the list via
  `PeopleLeaderboard.expenses(for:from:category:account:dateRange:)` with
  `route.range.range(payday: Payday.current)` (same `Payday.current` the leaderboard uses).
- Layout (ScrollView, Warm Cards — mirrors `PeopleLeaderboardView`):
  - Header card: `PersonAvatar` + name; attributed total via `MoneyText` (big); a caption
    "`N expenses · <range label>`".
  - "Filtered by: <Category> · <Account>" caption, shown only when a category/account
    filter is set (names the narrowing so the numbers make sense).
  - `ForEach` expenses → `ExpenseRow(expense:)` inside `.cardStyle()`, plus a small
    secondary date caption per card (`date.formatted(date: .abbreviated, time: .omitted)`).
    `ExpenseRow` itself is **not** modified (it's shared with the Expenses tab).
  - Attribution caption reused from the leaderboard ("each companion credited the full
    amount").
  - Empty state: `EmptyStateView(title: "No expenses in range", systemImage:
    "person.2.slash", message: …)` naming the active filters. Reached when a tighter filter
    leaves a still-ranked-elsewhere person with nothing.
- `.navigationTitle(route.person.name)`, inline.

## Navigation wiring
`ExpenseKu/ExpenseKu/Features/Insights/InsightsView.swift` (edit)
- Extend the existing `enum Destination: Hashable` from `case leaderboard` to also
  `case personExpenses(PersonExpensesRoute)` (associated value ⇒ Hashable synthesized).
- `.navigationDestination(for: Destination.self)` switches: `.leaderboard` →
  `PeopleLeaderboardView()`; `.personExpenses(let r)` → `PersonExpensesView(route: r)`.
  Both destinations share the one Insights `NavigationStack(path:)`.

`PersonExpensesRoute` (new, defined in `PersonExpensesView.swift`):
```
struct PersonExpensesRoute: Hashable {
    let person: Person            // PersistentModel ⇒ Hashable
    let category: Category?
    let account: Account?
    let range: DateRangeFilter    // String enum ⇒ Hashable
}
```

`ExpenseKu/ExpenseKu/Features/Insights/PeopleLeaderboardView.swift` (edit)
- Wrap `rankRow(...)` in `NavigationLink(value: InsightsView.Destination.personExpenses(
  PersonExpensesRoute(person: entry.person, category: categoryFilter,
  account: accountFilter, range: rangeFilter)))`, `.buttonStyle(.plain)`.
- Add a trailing `chevron.right` (secondary) to `rankRow` as the tap affordance
  (per wireframe). No layout/logic change beyond making the card a link.

## Control surface (so the screen is screenshot-able)
Reaching it means "Insights tab → push leaderboard → push person detail". Add a debug
deep-link handled where the Insights path is owned:
- `Shared/DebugLaunch.swift`: add `person-detail` to the `-startScreen` doc-comment.
- `InsightsView.task` (`#if DEBUG`): when `DebugLaunch.startScreen == "person-detail"`,
  compute `PeopleLeaderboard.ranked(from: expenses).first?.person` and set
  `path = [.leaderboard, .personExpenses(PersonExpensesRoute(person: p, category: nil,
  account: nil, range: .allTime))]`. Falls back to `[.leaderboard]` if no ranked person.
- Not a `fullScreenCover` screen ⇒ **no** `RootView.debugScreens` / `DebugHarness` entry
  (those are only for the modal editor/picker family). This is a tab-hosted push, like
  `leaderboard`.

## Fixtures
The existing `DebugLaunch.seedIfNeeded` set already tags companions:
`Budi` on the Jul 20 latte (with Fadil) and the Jul 28 "Ojek + makan" ⇒ ranked, 2
expenses across 2 categories, one account-less — a good multi-row + edge case for the
person detail. **No new fixtures required.**

## Test plan (behaviour oracle) — `ExpenseKuTests/PeopleLeaderboardTests.swift`
Write first, then implement until `scripts/shot.sh --test` is green.
- [ ] `expenses(for:)` returns only expenses tagged with that person (others excluded).
- [ ] Result is sorted newest-first by date.
- [ ] Honors category / account / dateRange filters (same gating as `ranked`).
- [ ] **Reconciliation:** for a person, `expenses(for: p, …).count == ranked(…) row
      sharedCount` and `sum(amount) == row total` under the same filters.
- [ ] A person tagged on nothing under a filter ⇒ empty array (drives the empty state).

## Interactive flow (simdrive.sh — required)
```
scripts/simdrive.sh launch -- -seedSampleData -startScreen leaderboard
scripts/simdrive.sh shot before-leaderboard      # Read: ranked rows, now with chevrons
scripts/simdrive.sh tap <px> <py>                 # tap the top person card (e.g. Fadil/Budi)
scripts/simdrive.sh shot after-detail            # Read: pushed detail — header total+count,
                                                  #   expense cards newest-first, attribution note
scripts/simdrive.sh tap <backBtn px> <py>         # tap ‹ back
scripts/simdrive.sh shot after-back              # Read: leaderboard again, filters intact
```
- [ ] before-leaderboard: rows show a chevron affordance.
- [ ] after-detail: detail header total & count match the row tapped; rows newest-first.
- [ ] after-back: returns to leaderboard with the same filters/scroll.
- Also `scripts/shot.sh person-detail -- -seedSampleData -startScreen person-detail` and
  `-a` (dark) for the static visual oracle vs the approved Variant A wireframe.

## Risks / guardrails touched
- **Model / vocabulary / 3-tab shell:** untouched. New screen hangs off the Insights stack;
  no new tab, no schema, no changed wording.
- **Money format:** reuse `MoneyText` / `.formattedIDR()` ⇒ IDR whole, right-aligned, mono.
- **Coral accent** stays reserved (rank #1 numeral only, as today); the new chevron/date use
  `Theme.textSecondary`, not accent.
- `ExpenseRow` is shared — we compose around it (a date caption in the card), we do **not**
  edit it, so the Expenses tab is unaffected.
- Debug-only deep-link is all `#if DEBUG`; nothing new ships in release.

---
Gate 2: user agrees the approach is sound before any code is written.
