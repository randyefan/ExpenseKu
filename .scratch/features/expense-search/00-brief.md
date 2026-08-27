# 00 — Brief · expense-search

## Problem
There is no way to find a past expense. The Expenses tab is a pay-cycle lens: it shows one
cycle at a time and you page it with ‹ ›. To answer "when did I buy that?" or "how much have
I spent on kopi?" you have to page backwards cycle by cycle and read every row. Once an
expense is a few cycles old it is effectively lost.

## Who it's for
The owner, looking back rather than logging. Two moments:
- **Find one thing** — "that dinner with Rina, what did it cost?" — needs to reach an old
  expense fast, and usually to open and edit it once found.
- **Total one thing** — "how much on kopi, ever?" — needs the sum of the matches, not just
  a list.

## What it is
A search field on the Expenses tab that searches **every expense ever logged**, ignoring the
cycle currently on screen. Revealed by pulling down on the list (standard iOS `.searchable`).
Typing replaces the cycle list with a flat, newest-first result list; clearing it restores
the cycle view untouched.

Decisions taken at this gate:
- **Scope: all time.** Search deliberately escapes the cycle lens — that is the point of it.
  Every result shows its date so you can tell which cycle a hit came from.
- **Matches: note + category name + people names + account name.** One box, no field picker.
  "kopi" hits notes, "Food" hits a category, "Rina" hits a companion, "BCA" hits an account.
  Case- and diacritic-insensitive substring matching.
- **Result total.** A summary line above the results: count + summed amount, IDR.
- **Results are live rows.** Tapping a result opens it in the expense editor, exactly like
  tapping a row in the cycle list.
- **Filter chips.** Chips to narrow the results by category and by date range. The date
  presets reuse the existing `DateRangeFilter` (All time / Last 30 days / This month / This
  pay period / This year) and the chip component reuses Insights' `FilterChip`, so search and
  Insights stay one vocabulary. Exact chip layout and behaviour are a Stage 1 decision.

## Acceptance criteria
- [ ] Pulling down on the Expenses list reveals a search field; it is hidden at rest and
      costs no vertical space when unused.
- [ ] Typing a query searches **all** expenses, not only the visible cycle — a match in a
      cycle months back appears without paging.
- [ ] A query matches against the note, the category name, any companion's name, and the
      account name; matching ignores case and diacritics.
- [ ] Results are a flat list ordered newest first, each row showing its date, so hits from
      different cycles are distinguishable.
- [ ] A summary line above the results shows the number of matches and their summed amount,
      IDR-formatted like the rest of the app.
- [ ] Tapping a result opens that expense in the editor; edits and deletes save normally, and
      the result list reflects them on return.
- [ ] Filter chips narrow the results by category and by date range; the summary total
      reflects the filters, and the chips reset when search is dismissed.
- [ ] A query with no matches shows an empty state naming the query, not a blank screen.
- [ ] Clearing or cancelling search restores the previously viewed cycle and lens unchanged.
- [ ] The List/Month toggle, cycle header and ‹ › paging keep their current behaviour when
      not searching.

## Out of scope
- **Searching by amount** (e.g. "> 50.000") — no numeric or comparison queries in v1.
- **Search anywhere else** — Insights and Manage tabs are untouched; this is the Expenses tab
  only.
- **Search history / saved searches / recent-query suggestions.**
- **Fuzzy or typo-tolerant matching** — plain substring only.
- **Searching inside the Month (calendar) lens** — a query shows the flat result list; the
  calendar grid is not filtered in place.
- **No data-model change.** No new SwiftData model, field, or migration.

---
Gate 0: user confirms "this is the feature." Do not start wireframes until approved.
