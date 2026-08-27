# 01 — Wireframe · expense-search

Low-fidelity ASCII wireframes for every screen and state. "Warm Cards" language, 3-tab shell,
no code. Rows are the existing `ExpenseRow` card (pastel category icon · bold category ·
optional note · grey meta line · bold amount, monospaced digits).

Two things were a genuine choice; both are now **decided** (2026-08-28):
- **§A — how a result row shows its date → A1**, a small grey date on each row, flat list.
- **§B — where the category + period filters live → B1**, two `FilterChip` menus under the
  search bar.

The screens below are drawn with A1 + B1 in place. The rejected alternatives are kept at the
bottom for the record.

---

## Screen: Expenses tab — idle, search bar hidden (unchanged from today)

```
┌──────────────────────────────────────┐
│ [📅]                            (+)  │  ← nav bar, unchanged
│                                      │
│      ‹    25 Aug – 24 Sep    ›       │  ← CycleHeader
│            Rp 1.240.000              │     (coral hero total)
│                                      │
│      [  List  |   Month  ]           │  ← SegmentedToggle
│                                      │
│  Today                     45.000    │  ← DayGroupHeader
│  ┌────────────────────────────────┐  │
│  │ 🍜  Makan              30.000  │  │
│  │     Nasi padang                │  │
│  │     💳 BCA · 👥 Rina           │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               15.000  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
The search field is **not** rendered at rest — it lives above the list's scroll origin
(standard `.searchable`), so it costs zero vertical space until pulled down.

Controls:
- pull down on the list → reveals the search field (§2)
- everything else behaves exactly as today

---

## Screen: search revealed, query empty

```
┌──────────────────────────────────────┐
│ [🔍 Search expenses          ] Cancel│  ← revealed by pull-down; focused
│                                      │
│      ‹    25 Aug – 24 Sep    ›       │  ← cycle view still visible underneath,
│            Rp 1.240.000              │     untouched
│      [  List  |   Month  ]           │
│  Today                     45.000    │
│  ┌────────────────────────────────┐  │
│  │ 🍜  Makan              30.000  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```
An empty query changes nothing — you are still looking at the cycle. No "suggestions" screen,
no dimming. Results appear on the first typed character.

Controls:
- `Cancel` / `✕` → dismiss search, restore the cycle view and lens exactly as they were
- typing → §3

---

## Screen: results (query typed)   ← the core state

**The cycle header, the coral cycle total and the List/Month toggle all hide while a query is
active.** Results are all-time, so a "25 Aug – 24 Sep" header above them would be a lie, and
the coral hero is reserved for one total per screen — while searching, that total is the
results total.

```
┌──────────────────────────────────────┐
│ [🔍 kopi                   ✕ ] Cancel│
│                                      │
│ ( Category: All ⌄ ) ( Period: All ⌄ )│  ← B1: two FilterChip menus
│                                      │
│   12 results          Rp 340.000     │  ← summary line: count (secondary)
│  ──────────────────────────────────  │     + summed total (coral hero)
│                                      │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               22.000  │  │
│  │     Kopi kenangan       2 Sep  │  │  ← A1: date, grey, monospaced
│  │     💳 BCA                     │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               48.000  │  │
│  │     Kopi + roti        18 Jul  │  │
│  │     💳 GoPay · 👥 Rina         │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 🍜  Makan              25.000  │  │  ← matched on the *note*, not category
│  │     Kopi Tuku          3 Mar 25│  │  ← year appears once it is not this year
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**A1 date rules.** The date sits on the row's trailing edge, `dsCaption` / secondary /
monospaced digits — the same treatment as a day header's total, so it reads as metadata, never
as money. Format: `2 Sep` within the current year, `3 Mar 25` outside it. A row with no note
still shows its date (the date slot is its own line, not appended to the note).

Controls:
- tap a row → opens that expense in `ExpenseEditorView` (sheet on iPhone, detail pane on iPad)
- swipe a row → **Delete**, same as in the cycle list. The row leaves the results immediately
  and the summary line above recounts and re-totals:

```
│   12 results          Rp 340.000     │        │   11 results          Rp 318.000     │
│  ┌────────────────────────────────┐  │        │  ┌────────────────────────────────┐  │
│  │ ☕  Kopi   ◀swipe◀     22.000  │  │  ───▶  │  │ ☕  Kopi               48.000  │  │
│  │     Kopi kenangan  [ Delete ]  │  │        │  │     Kopi + roti        18 Jul  │  │
│  └────────────────────────────────┘  │        │  └────────────────────────────────┘  │
```
  Deleting here deletes the expense outright — it is gone from the cycle list too, not merely
  from the results.
- `✕` → clears the query back to §2 · `Cancel` → back to §1
- scroll → results are one flat scroll, newest first, no paging

---

## Screen: results, no matches

```
┌──────────────────────────────────────┐
│ [🔍 xyzzy                  ✕ ] Cancel│
│                                      │
│ ( Category: All ⌄ ) ( Period: All ⌄ )│  ← filters stay on screen
│                                      │
│              ╭───────╮               │
│              │   🔍  │               │  ← EmptyStateView badge
│              ╰───────╯               │
│                                      │
│           No results                 │
│    Nothing matches “xyzzy”.          │
│                                      │
└──────────────────────────────────────┘
```
The query is named back to you so a typo is obvious. Filters stay on screen — if the reason
for zero results is a narrow filter, you must be able to see and undo it without retyping.

Variant of the same state, when **filters** are what emptied it:

```
│           No results                 │
│  Nothing matches “kopi” in Makan     │
│  during This month.                  │
```

---

## Screen: results, a filter applied

```
┌──────────────────────────────────────┐
│ [🔍 kopi                   ✕ ] Cancel│
│ (Category: Kopi ⌄) (Period: This year ⌄)  ← a set chip reads its value, not "All"
│                                      │
│   4 results            Rp 92.000     │  ← count + total both reflect the filter
│  ──────────────────────────────────  │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               22.000  │  │
│  │     Kopi kenangan       2 Sep  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

Each chip is the existing `FilterChip` fronting a `Menu`: Category lists "All" + every
category; Period lists the five `DateRangeFilter` presets. A chip at its default reads
`Category: All` / `Period: All time`; a set chip reads its value, which is the only signal
needed since the value is spelled out on the chip itself.

Filters narrow the current query; they never search on their own. They reset to
All / All time when search is dismissed.

---

## Screen: search when the app has no expenses at all

```
┌──────────────────────────────────────┐
│      ‹    25 Aug – 24 Sep    ›       │
│            Rp 0                      │
│      [  List  |   Month  ]           │
│              ╭───────╮               │
│              │   📄  │               │
│              ╰───────╯               │
│          No expenses yet             │
│    Tap + to log your first expense.  │
└──────────────────────────────────────┘
```
No search bar is offered — there is nothing to search, and a pull-down onto an empty state has
nothing to pull. The first-run screen stays exactly as it is today.

---

## Screen: tapping a result (iPhone)

```
   results  ──tap row──▶  ┌──────────────────────┐
                          │ Cancel  Edit   Save  │  ← ExpenseEditorView, as a sheet
                          │       Rp 22.000      │     (same sheet the cycle list uses)
                          │  ☕ Kopi             │
                          │  Kopi kenangan       │
                          └──────────────────────┘
                                    │
                              Save / Cancel
                                    ▼
                    back to the results, query intact,
                    the edited row updated in place
                    (or gone, if the edit no longer matches)
```
On iPad/Mac the row selects into the existing detail pane instead of a sheet — the results
list simply takes the sidebar's place while searching.

---

# §A — How a result row shows its date  ·  DECIDED: A1

### A1 · date on the row, trailing, under the amount  ✅ CHOSEN

```
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               22.000  │  │
│  │     Kopi kenangan       2 Sep  │  │  ← grey, dsCaption, monospaced
│  │     💳 BCA                     │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               25.000  │  │
│  │     Kopi Tuku          3 Mar 25│  │  ← year shown once it is not this year
│  └────────────────────────────────┘  │
```
Flat list, every row self-dating. Scattered hits across years read fine. Costs a small
addition to `ExpenseRow` (a date slot only search fills).

### A2 · day-group headers, like the cycle list  ❌ rejected

```
│  Wed, 2 September 2026      22.000   │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               22.000  │  │
│  └────────────────────────────────┘  │
│  Sat, 18 July 2026          48.000   │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi + roti        48.000  │  │
│  └────────────────────────────────┘  │
│  Tue, 3 March 2026          25.000   │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi Tuku          25.000  │  │
```
Reuses `DayGroupHeader` + `DayLabel` untouched (plus a year). Identical to the cycle list, so
nothing new to learn — but scattered results become a stack of one-row sections, and each
header repeats a total that equals its single row.

### A3 · month-group headers  ❌ rejected

```
│  SEPTEMBER 2026                      │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi               22.000  │  │
│  │     Kopi kenangan          2   │  │  ← day number only, inside the month
│  └────────────────────────────────┘  │
│  JULY 2026                           │
│  ┌────────────────────────────────┐  │
│  │ ☕  Kopi + roti        48.000  │  │
│  │     Kopi kenangan         18   │  │
```
Compact for long result sets and gives a sense of "when did this cluster". Adds a grouping
concept the app does not use anywhere else today.

---

# §B — Where the category + period filters live  ·  DECIDED: B1

### B1 · two menu chips under the search bar  ✅ CHOSEN

```
│ [🔍 kopi                   ✕ ] Cancel│
│  ( Category: All ⌄ ) ( Period: All ⌄)│  ← existing `FilterChip` menus
│   12 results          Rp 340.000     │
```
active:
```
│  ( Category: Kopi ⌄ ) ( Period: This year ⌄ )
```
Reuses the leaderboard's `FilterChip` verbatim, so search and Insights speak one language.
One compact row, always visible, both filters readable at a glance. Two chips fit; a third
would not.

### B2 · scrolling period presets + a category chip  ❌ rejected

```
│ [🔍 kopi                   ✕ ] Cancel│
│ [All time][30 days][This month][This ▸│  ← `PeriodFilterChips`, coral = selected
│  ( Category: All ⌄ )                  │
│   12 results          Rp 340.000     │
```
Period is one tap instead of two (no menu to open) and the selected preset is visible without
opening anything — this is exactly what Insights does. Costs two rows of vertical space above
every result set.

### B3 · a single Filter button → sheet  ❌ rejected

```
│ [🔍 kopi                   ✕ ] Cancel│
│   12 results   Rp 340.000  [⚙︎ 2]    │  ← badge = how many filters are on
│  ──────────────────────────────────  │
│  results…                            │
                    │ tap ⚙︎
                    ▼
        ┌──────────────────────────┐
        │ Cancel   Filters   Reset │
        │  Category      All    ⌄  │
        │  Period   This year   ⌄  │
        │      [    Apply     ]    │
        └──────────────────────────┘
```
Maximum room for results and it scales if filters ever grow past two. But the filters are
out of sight, so a narrow filter that is quietly eating your results is easy to forget —
which is exactly the failure the "no results" state above has to explain.

---

## Flow

```
Expenses tab (cycle view)
   │ pull down
   ▼
search field focused, query empty ── Cancel ──▶ back to cycle view, lens + cycle intact
   │ type
   ▼
results (all-time, newest first) ◀── ✕ clears query
   │                    ▲
   │ tap row            │ save / cancel
   ▼                    │
expense editor ─────────┘
```
Search hangs off the Expenses tab only. It never changes which cycle you were viewing, and
dismissing it always returns you to exactly where you were.

## Decisions taken at gate 1 (2026-08-28)

- §A → **A1** (date on each row) · §B → **B1** (two `FilterChip` menus).
- While a query is active the **cycle header, coral cycle total and List/Month toggle hide**;
  the results total takes over the one-hero-total-per-screen slot.
- Results support **swipe-to-delete**, matching the cycle list. The summary line recounts and
  re-totals after a delete.
- An empty query leaves the cycle view untouched — no suggestions screen.
- No search bar at all when the store is empty.

---
Gate 1: show these via AskUserQuestion (one variant per preview) and loop until the user
agrees on the UX. Then advance to the tech spec.
