# 00 — Brief · person-expenses

## Problem
The People leaderboard ranks people by how much you've spent with them, but the rows
are a dead end. When you tap a person you can't see *which* expenses make up their
total — there's no way to drill into the list of expenses that person is tagged on.

## Who it's for
Anyone using the People leaderboard (Insights → "Who you spend with") who sees a
surprising total next to a name and wants to know what's behind it — "why is my total
with Budi so high, which outings were those?"

## Acceptance criteria
- [ ] Tapping a person row on the leaderboard opens a detail screen for that person.
- [ ] The detail screen lists every expense that person is tagged on, honoring the
      leaderboard's active filters (period / category / account).
- [ ] Each listed expense shows enough to identify it: title/merchant, category, date,
      and amount (money formatted per app convention — IDR whole, right-aligned, mono).
- [ ] The detail screen shows the person's attributed total and expense count (the same
      numbers the leaderboard row shows), so the drill-down reconciles with the row.
- [ ] Expenses are listed newest-first.
- [ ] Empty state: if the active filters leave the person with no expenses, the screen
      says so rather than showing a blank list.
- [ ] Back navigation returns to the leaderboard with its filters intact.

## Out of scope
- Editing an expense from this screen (tapping through to the editor) — display only
  for now, unless we decide otherwise at the wireframe gate.
- Changing the attribution rule (full amount to each companion stays as-is).
- Any change to the leaderboard ranking, filters, or vocabulary.

---
Gate 0: user confirms "this is the feature." Do not start wireframes until approved.
