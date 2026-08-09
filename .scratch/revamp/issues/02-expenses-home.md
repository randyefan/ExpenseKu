# 02 — Expenses home (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/home.png`, `refs/home-empty.png`
Files: `Features/Expenses/ExpensesView.swift`, `ExpenseRow.swift` (+ DesignSystem)

Reskin the home screen to Warm Cards. Cycle navigator becomes a **card**: ‹ › arrows, cycle
title (end-month, e.g. "August 2026"), date span below, an uppercase "SPENDING" label, and the
**hero total in coral** (see spec tension note). Day groups get uppercase gray headers
("TODAY" / "YESTERDAY" / "THU, 6 AUGUST"). Each expense = a white rounded card: pastel
`CategoryIcon`, bold category name, meta line (date · account w/ card icon · companions), bold
charcoal amount right-aligned monospaced, optional note line. Floating pill tab bar, coral +.

## States
- Populated cycle (`home.png`), empty cycle + no-expenses-at-all (`home-empty.png` — header/arrows stay).

## Verify
`scripts/shot.sh home -- -seedSampleData -startTab expenses`, compare to `refs/home.png`.
`scripts/shot.sh home-empty -- -startTab expenses` (no seed) vs `refs/home-empty.png`.
Dark: add `-a`. Then `scripts/shot.sh --test`.

## Guardrails
Keep swipe-to-delete, day grouping, bounded arrows, spending-only header (no income/net),
iPhone-push adaptivity. Behaviour unchanged.
