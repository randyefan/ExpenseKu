# 02 — Tech spec · expense-search

Implements the gate-1 wireframe: all-time search on the Expenses tab, A1 result rows (date on
each row) + B1 filters (two `FilterChip` menus), swipe-to-delete kept.

App target deploys to **iOS 26.0**, Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

## Data model

**No change.** No new `@Model`, no new field, no migration. Search reads the `@Query` array
`ExpensesView` already holds (`@Query(sort: \Expense.date, order: .reverse)`), so it costs no
new fetch and stays live — an edit or delete anywhere updates the results automatically.

The one thing search must *not* do is hold a `Category` model in view state as the filter
value (the lesson of commit 0c4fcc9, "carry identifiers, not live models"). The category
filter is therefore a **`String?` category name**, which also keeps the pure layer free of
SwiftData identity. Two categories sharing a name would both match; the app's duplicate-name
prompt makes that rare and matching both is the harmless reading.

## Architecture — a pure layer, like `CycleContents`

Search logic goes in a `nonisolated`, SwiftData-free layer so it is unit-testable without a
`ModelContainer`, matching `CycleContents` / `SpendSummary` / `PeopleLeaderboard`.

```swift
// Features/Expenses/ExpenseSearch.swift
nonisolated struct ExpenseSearchResults {
    let expenses: [Expense]      // matches, newest first
    let total: Decimal           // sum of the matches
    var count: Int { expenses.count }
    var isEmpty: Bool { expenses.isEmpty }

    init(query: String,
         allExpenses: [Expense],
         categoryName: String? = nil,
         dateRange: ClosedRange<Date>? = nil)
}

nonisolated enum ExpenseSearchMatch {
    static func tokens(_ query: String) -> [String]           // folded, split on whitespace
    static func haystack(_ expense: Expense) -> String        // note + category + people + account
    static func matches(_ expense: Expense, tokens: [String]) -> Bool
}
```

Rules the pure layer owns:
- **Normalization**: `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)`
  on both query and haystack, so "cafe" finds "Café" and "KOPI" finds "kopi".
- **Multi-word = AND.** The query splits on whitespace and *every* token must appear somewhere
  in the haystack, so "kopi bca" finds coffee paid from BCA. (Judgment call — the brief only
  said "substring". Flag it at the gate if you want a single literal substring instead.)
- **Empty / whitespace-only query → no results**, never "everything". The view never renders
  the results lens for an empty query anyway, but the pure layer must not lie if asked.
- **Sort is owned here** — `sorted { $0.date > $1.date }`, not inherited from the caller's
  `@Query` order, so the tests pin it.
- **Nil relationships are skipped**, not stringified. A nil category contributes nothing to
  the haystack: typing "uncategorized" does **not** match an uncategorized expense, because
  that word is a rendering, not the owner's data.
- **Range test is inclusive** on both ends (`dateRange.contains`).

```swift
// Features/Expenses/SearchDateLabel.swift
nonisolated enum SearchDateLabel {
    static func text(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String
}
```
Same calendar year as `now` → `.dateTime.day().month(.abbreviated)` → "2 Sep". Any other year
→ `.dateTime.day().month(.abbreviated).year(.twoDigits)` → "3 Mar 25". Deliberately **not**
`DayLabel`: no "Today"/"Yesterday" here, because "Today" sitting next to "3 Mar 25" in one
scrolling list reads as two different kinds of thing. `now` and `calendar` are injectable so
the tests pin the year boundary.

## Files touched

**New**
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseSearch.swift` — the pure layer above.
- `ExpenseKu/ExpenseKu/Features/Expenses/SearchDateLabel.swift` — the row's date string.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseSearchLens.swift` — the results surface:
  filters + summary + `List` of rows + swipe-delete, or the no-results `EmptyStateView`.
  Sits beside `CycleListLens` / `CycleCalendarLens` as the tab's third lens.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseSearchSummary.swift` — the "12 results ·
  Rp 340.000" line. Count is `dsCaption`/secondary; the total is the coral hero, which is free
  to use here only because the cycle hero is hidden while searching.
- `ExpenseKu/ExpenseKu/Features/Expenses/ExpenseSearchFilters.swift` — the two `FilterChip`
  menus (Category: All + every category name · Period: the five `DateRangeFilter` cases).
- `ExpenseKu/ExpenseKuTests/ExpenseSearchTests.swift`
- `ExpenseKu/ExpenseKuTests/SearchDateLabelTests.swift`

**Edited**
- `Features/Expenses/ExpenseRow.swift` — add `var dateLabel: String? = nil`. When set, it
  renders on the row's trailing edge under the amount, `dsCaption` / `Theme.textSecondary` /
  `monospacedDigit` — the day-header total's treatment, so it reads as metadata, not money.
  Default `nil` means **the cycle list and calendar render exactly as today**.
- `Features/Expenses/ExpenseListRow.swift` — pass `dateLabel` through.
- `Features/Expenses/ExpensesView.swift` — the search state and the branch (below).
- `Shared/DebugLaunch.swift` — `-startScreen` doc-comment + fixtures.
- `RootView.swift` — route the new `search*` values to the Expenses tab.
- `scripts/simdrive.sh` — **add a `swipe` command** (see "Interactive flow").

**Proposed move (flag at the gate):** `Features/Insights/FilterChip.swift` →
`DesignSystem/FilterChip.swift`. It becomes a component two features share, and it is already
pure chrome with no Insights knowledge. Synchronized file groups mean moving it on disk needs
no `project.pbxproj` edit. Say the word and I'll leave it in place and reference it across
features instead — it compiles either way (one module).
`DateRangeFilter` **stays** in Insights and is referenced; it is still analytics vocabulary.

### `ExpensesView` changes

```swift
@Query(sort: \Category.name) private var categories: [Category]   // new — feeds the chip menu
@State private var searchText = ""
@State private var searchCategoryName: String?      // nil = All
@State private var searchRange: DateRangeFilter = .allTime
private var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }
```

The sidebar column becomes: if `isSearching`, render `ExpenseSearchLens`; otherwise the
existing `CycleHeader` + `SegmentedToggle` + list/calendar, untouched. `.searchable` is applied
to the sidebar content so the field lands in its navigation bar:

```swift
.searchable(text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search expenses")
.onChange(of: searchText) { _, new in
    if new.isEmpty { searchCategoryName = nil; searchRange = .allTime }   // filters reset with the query
}
```

Driving off `searchText` rather than `@Environment(\.isSearching)` is deliberate: `isSearching`
is only readable *inside* a child of the modifier, and the wireframe's rule is "an empty query
shows the cycle" — which is a statement about the text, not about focus.

The `.searchable` modifier is **not** applied when the store is empty (`expenses.isEmpty`), per
the wireframe: nothing to search, nothing to pull down onto.

Delete reuses the existing `delete(_:from:)` — same `context.delete` + one `save()` per swipe
batch — so deleting from results deletes the expense outright, exactly as the wireframe says.

## Control surface (so the screen is screenshot-able)

Search is **in-tab state** of `ExpensesView`, like `calendar`/`calendar-day` — it routes
through `RootView`, *not* `DebugHarness`, and is **not** added to `DebugScreen.coverScreens`.

1. `Shared/DebugLaunch.swift` — extend the `-startScreen` doc-comment with
   `search|search-empty`.
2. `RootView.applyDebugLaunch()` — add `"search", "search-empty"` to the case that sets
   `selection = .expenses`.
3. `ExpensesView`'s existing `#if DEBUG .task` — add:
   ```swift
   case "search":       searchText = "kopi"     // populated results, 3 cycles, 2 years
   case "search-empty": searchText = "xyzzy"    // the no-results state
   ```

Known limit, stated up front: a prefilled `searchText` renders the **results**, but does not
put the search *field* into its focused/Cancel state — nothing in `.searchable` is
programmatically focusable from a launch arg. So `shot.sh` proves the results area; the field's
own behaviour (reveal, focus, Cancel) is proved by `simdrive.sh` below, which is the point of
having both oracles.

New shot targets:

| Screen | launch args |
|--------|-------------|
| Search results | `-seedSampleData -startScreen search` |
| Search, no results | `-seedSampleData -startScreen search-empty` |

## Fixtures

`DebugLaunch.seedIfNeeded` currently seeds 6 expenses across Jul–Aug 2026, all in one year.
Search needs cross-year and diacritic coverage, so:

- Give the local `day(_:_:_:_:)` helper a `year: Int = 2026` parameter (existing calls are
  unchanged by the default).
- Add two expenses:
  ```swift
  // Prior year → exercises SearchDateLabel's "3 Mar 25" branch, and matches "kopi"
  // on its NOTE while sitting in the Makan category — proving note-matching is
  // independent of category-matching.
  Expense(amount: 35_000, date: day(12, 18, 10, 0, year: 2025), note: "Kopi Tuku",
          category: makan, people: [tarisa], account: cash),
  // Diacritic edge case: "cafe" must find "Café".
  Expense(amount: 55_000, date: day(6, 11, 9, 0), note: "Café Kenangan",
          category: kopi, people: [], account: gopay),
  ```

That gives `-startScreen search` (query "kopi") **4 hits across 3 pay cycles and 2 years** —
two by category (Kopi), two by note — which is exactly the mixed evidence the results screen
needs to be worth screenshotting. Existing rows already cover a person match ("Tarisa"), an
account match ("GoPay"), and an account-less expense.

## Test plan (behaviour oracle)

`ExpenseSearchTests.swift` — pure, no `ModelContainer`, fixed gregorian calendar, following
`ExpenseDayGroupingTests`' shape:

- [ ] matches a **note**, case-insensitively ("KOPI" finds "Morning coffee"… i.e. "coffee")
- [ ] matches a **category** name
- [ ] matches a **person's** name
- [ ] matches an **account** name
- [ ] **diacritic-insensitive**: "cafe" finds "Café Kenangan"
- [ ] a non-matching query returns **empty**, total 0
- [ ] an **empty / whitespace-only** query returns empty — not everything
- [ ] results are **newest first**, even when the input array is shuffled
- [ ] `total` is the **sum of the matches only**; `count` agrees with `expenses.count`
- [ ] **multi-token AND**: "kopi cash" matches only expenses satisfying both; "kopi zzz" none
- [ ] **category filter** narrows results and the total
- [ ] **date-range filter** narrows results; boundary dates are **inclusive** at both ends
- [ ] **query + both filters compose** (all three applied together)
- [ ] an expense with **nil category, nil account, empty people** doesn't crash and still
      matches on its note
- [ ] "uncategorized" does **not** match a nil-category expense

`SearchDateLabelTests.swift`:
- [ ] same year → "2 Sep" (no year component)
- [ ] different year → includes the two-digit year
- [ ] 31 Dec vs 1 Jan across a year boundary flips the format
- [ ] today's date still renders as a date, never "Today"

Run: `scripts/shot.sh --test` (must stay green; suite was 142 tests).

## Interactive flow (simdrive.sh — required)

**Harness change first:** `simdrive.sh` has `launch/shot/tap/key/bounds` but **no drag**, so
swipe-to-delete cannot be driven today. Add:

```
scripts/simdrive.sh swipe <x1> <y1> <x2> <y2>    # cliclick dd: → dm: → du:, pixel coords
```
mapped through the same `read_mapping` as `tap`. Additive, benefits every later feature.

Useful discovery: `key` sends AppleScript `keystroke "$KEY"`, so **`key kopi` types the whole
word** in one call — no per-character stepping.

Coordinates are pinned from the first shot of the run (that is the documented workflow); the
steps below state the pixel to pick and the state to confirm.

- `simdrive.sh launch -- -seedSampleData -startTab expenses`
- [ ] `shot s01-idle` → cycle view; note where the search field sits (see Risk 1)
- [ ] `tap` the search field → `shot s02-focused` → field focused, **Cancel** appears, cycle
      view still underneath, unchanged
- [ ] `key kopi` → `shot s03-results` → cycle header + coral cycle total + List/Month toggle
      **gone**; chips row present; summary reads **4 results · Rp 140.000**; rows show dates
      including one **"18 Dec 25"**
- [ ] `tap` the Period chip → `shot s04-menu` → menu lists the five presets
- [ ] `tap` "This year" → `shot s05-filtered` → the Dec-2025 row is **gone**; count and total
      both drop
- [ ] `tap` the Category chip → `tap` "Kopi" → `shot s06-filtered2` → only Kopi-category rows;
      both chips read their values
- [ ] `tap` the first result row → `shot s07-editor` → the **editor sheet for that expense**
      (amount matches the row tapped — this is the tap-to-edit criterion)
- [ ] `key escape` → `shot s08-back` → back on results with **query and both filters intact**
- [ ] `swipe` right-to-left across the first row → `shot s09-swipe` → **Delete** revealed
- [ ] `tap` Delete → `shot s10-deleted` → row gone; summary **recounts and re-totals**
- [ ] `tap` Cancel → `shot s11-restored` → cycle view back, **same cycle, same lens**, and the
      deleted expense is absent there too
- [ ] `simdrive.sh launch -a -- -seedSampleData -startScreen search` → `shot s12-dark` → the
      results screen reads in dark mode
- [ ] `simdrive.sh launch -- -startTab expenses` (no seed) → `shot s13-virgin` → **no search
      field at all** on the first-run empty state

## Risks / guardrails touched

1. **The `.searchable` drawer may not hide the way the wireframe drew it.** The wireframe says
   the field costs zero vertical space at rest. `navigationBarDrawer(displayMode: .automatic)`
   normally gives that by coupling to the scroll view — but here the `List` is nested inside a
   `VStack` under `CycleHeader` + `SegmentedToggle`, so the drawer may fail to couple and just
   stay permanently visible (which is the "always visible" option you did *not* pick).
   **This gets resolved by screenshot in Stage 3, not by argument.** If `.automatic` won't
   hide, the fallback is iOS 26's `.searchToolbarBehavior(.minimize)`, which parks search as a
   🔍 in the toolbar and expands it on tap — still one gesture, still zero resting cost. I'll
   shoot it and show you which one you're getting before calling Stage 3 done.
2. **Coral is a reserved accent.** The results total takes the hero coral only because the
   cycle hero is hidden while searching — one hero total per screen, never two.
3. **Guardrails held**: no model change, 3-tab shell untouched, money stays IDR whole numbers
   via `formattedIDR()`, right-aligned and monospaced. Each list state has an empty state.
   Dark mode and Dynamic Type verified in Stage 3 (`ExpenseRow`'s new date must not crowd the
   amount at accessibility sizes — the shot at XXL is the check).
4. **`ExpenseRow` is shared** by the cycle list and the calendar's day list. The new parameter
   defaults to `nil`, so both keep rendering exactly as today; the search lens is the only
   caller that passes it.
5. **Performance**: search is O(n) string folding over an already-materialized array, on every
   keystroke. Fine at personal-expense-app scale (hundreds to low thousands). If it ever
   bites, the fix is to fold the haystack once per expense per query — noted, not built.
6. **`scripts/simdrive.sh` is shared harness code**, not feature code. The `swipe` addition is
   additive and shouldn't disturb existing flows, but it does touch a file other features use.

---
Gate 2: user agrees the approach is sound before any code is written.
