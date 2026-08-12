# 01 — Wireframe · person-expenses

Low-fidelity ASCII wireframes for every screen and state. Stays in the "Warm Cards"
language and the 3-tab shell. No code. The only new screen is **Person detail**, pushed
onto the Insights nav stack from a leaderboard row.

## Screen: People leaderboard — row becomes tappable (unchanged layout)
```
┌───────────────────────────────────────┐
│  Who you spend with                    │
│  [Period ▾][Category ▾][Account ▾]     │
│                                        │
│  ┌───────────────────────────────┐  ›  │  ← whole card is a NavigationLink now;
│  │ 1  (BD) Budi                  │     │    a chevron hints it's tappable
│  │        12 expenses    Rp 480k │     │
│  └───────────────────────────────┘     │
│  ┌───────────────────────────────┐  ›  │
│  │ 2  (AN) Anas   4 exp   Rp 90k │     │
│  └───────────────────────────────┘     │
└───────────────────────────────────────┘
```
Controls:
- Tap a person card → push **Person detail** for that person, passing the leaderboard's
  active Period / Category / Account filters so the numbers match.

---

## Screen: Person detail — default (VARIANT A: flat list, newest-first)
```
┌───────────────────────────────────────┐
│  ‹ People            Budi              │  ← nav bar; back returns w/ filters intact
│                                        │
│         (BD)   Budi                    │  ← header card: avatar + name
│         Rp 480.000                     │     attributed total (big, mono)
│         12 expenses · All time         │     count + active-range label
│                                        │
│  Filtered by: Food · Cash             ⓘ│  ← shown only when category/account set
│                                        │
│  ┌───────────────────────────────┐     │
│  │ (🍜) Food            Rp 45.000 │     │  ← reuses ExpenseRow
│  │      Dinner · Cash             │     │
│  │      12 Aug 2026               │     │  ← date line added for detail context
│  └───────────────────────────────┘     │
│  ┌───────────────────────────────┐     │
│  │ (🚕) Transport       Rp 30.000 │     │
│  │      Grab · Cash               │     │
│  │      10 Aug 2026               │     │
│  └───────────────────────────────┘     │
│              … newest → oldest …        │
│                                        │
│  Each shared expense credits Budi the  │  ← same attribution caption as leaderboard
│  full amount.                          │
└───────────────────────────────────────┘
```
Controls:
- `‹ People` → pop back to leaderboard, filters preserved.
- Rows are display-only (no tap-through to editor — per brief's out-of-scope).

## Screen: Person detail — default (VARIANT B: grouped by day, like the Expenses tab)
```
┌───────────────────────────────────────┐
│  ‹ People            Budi              │
│                                        │
│         (BD)   Budi                    │
│         Rp 480.000                     │
│         12 expenses · All time         │
│                                        │
│  Today · Rp 75.000                     │  ← day header w/ per-day total (matches
│  ┌───────────────────────────────┐     │    the Expenses list day headers)
│  │ (🍜) Food            Rp 45.000 │     │
│  │      Dinner · Cash             │     │
│  └───────────────────────────────┘     │
│  ┌───────────────────────────────┐     │
│  │ (☕) Coffee          Rp 30.000 │     │
│  └───────────────────────────────┘     │
│                                        │
│  10 Aug 2026 · Rp 30.000               │
│  ┌───────────────────────────────┐     │
│  │ (🚕) Transport       Rp 30.000 │     │
│  └───────────────────────────────┘     │
│                                        │
│  Each shared expense credits Budi the  │
│  full amount.                          │
└───────────────────────────────────────┘
```
Controls: same as Variant A. Day grouping reuses the Expenses tab's day-header +
per-day-total component; individual rows drop the redundant per-row date.

---

## Screen: Person detail — empty state (filters exclude everything)
```
┌───────────────────────────────────────┐
│  ‹ People            Budi              │
│                                        │
│         (BD)   Budi                    │
│         Rp 0                           │
│         0 expenses · This month        │
│                                        │
│  Filtered by: Food · Cash             ⓘ│
│                                        │
│              ( person.2 slash )        │
│           No expenses in range         │
│     Budi has no Food expenses paid     │
│       from Cash this month.            │
│                                        │
└───────────────────────────────────────┘
```
Reachable when a leaderboard filter combination leaves the person with nothing (a person
can appear on the leaderboard for "All time / All" but have nothing under a tighter
filter). Message names the active filters so it's clear *why* it's empty.

## Flow
```
Insights tab → People leaderboard → [tap person card]
      → Person detail (push, carries Period/Category/Account)
      → [‹ back] → People leaderboard (filters intact)
```
Hangs off the existing Insights navigation stack. No new tab, no change to the 3-tab shell.

---
Gate 1: show these via AskUserQuestion (one variant per preview) and loop until the user
agrees on the UX. Then advance to the tech spec.
