# ADR-0003 — Pay-period filter preset: KV-store anchor, pure period math

Status: Accepted (the "analytics-only / not the primary lens" scope is superseded by ADR-0004)
Date: 2026-08-09

## Context

The owner is paid on a day other than the 1st, so calendar-month Insights don't align
with how they actually experience a spending cycle. We want a **"This pay period"** preset
in the Insights date filter, anchored to a configurable payday (day-of-month). This is
single-user and analytics-only — it must not drag in budgets, income, or a new persistence model.

Two questions needed deciding: **where the payday anchor lives** (it should sync across the
owner's devices), and **how the period is computed** without polluting the pure analytics layer.

## Decision

- **Anchor stored in `NSUbiquitousKeyValueStore`** (iCloud key-value), not SwiftData.
  A SwiftData "settings singleton" would ride the existing CloudKit container, but
  SwiftData+CloudKit **cannot enforce unique constraints** (see ADR-0002), so a singleton
  row can silently duplicate across devices — the same corruption class we guard against for
  Category/Person. A KV-store preference syncs one integer without that risk. **Default = 1**,
  making "This pay period" identical to "This month" until changed. Valid range 1–31.
- **Period math stays pure.** `DateRangeFilter.range(now:calendar:)` gains a `payday:`
  parameter rather than reaching out to the KV-store itself. The View reads the preference
  and threads it in; the enum ignores it for every non-pay-period case.
- **Semantics:** "This pay period" = `start ... now`, `start` = most recent payday
  on-or-before `now`. **Ends at now** (spend-so-far), matching existing `thisMonth`.
  Payday beyond a month's length **clamps to the last valid day** (31 → Feb 28/29).
- **Monthly, single owner, one anchor.** No semi-monthly/biweekly cycles, no per-person
  paydays, no weekend/"last working day" shifting, no "Last pay period" — all deferred
  until actually needed.

## Consequences

- Adding the preset requires **no schema change and no migration** — one synced preference
  plus a wider pure function.
- The analytics layer remains unit-testable in isolation (anchor is just a parameter),
  consistent with how aggregation is already separated from UI.
- The payday is configured via an **inline stepper** in Insights; no Settings screen exists
  yet, and we don't build one until a second preference forces it.
- "Pay period" enters the ubiquitous language (see `CONTEXT.md`).
- Escalating later to biweekly cycles, a "Last pay period" comparison, or pay-period as the
  app's primary lens would each be a new decision building on this one.
