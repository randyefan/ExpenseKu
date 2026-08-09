# ADR-0004 — Pay cycle as the primary home lens

Status: Accepted
Date: 2026-08-09
Supersedes: the "analytics-only, not the app's primary lens" scope limit of ADR-0003

## Context

ADR-0003 introduced the pay period as an **Insights-only** date filter and explicitly
ruled out making it "the app's primary lens" or "a redefinition of 'month' elsewhere."
Living with it, the owner wants the **Expenses home screen** itself framed by the pay
cycle rather than the calendar month — browse one cycle at a time, anchored to a
configurable Monthly Start Date, the way a billing-cycle tracker works. That directly
overrides the earlier scope limit, so it needs its own decision rather than a silent drift.

## Decision

- **The Expenses home is now framed by the pay cycle.** `ExpensesView` shows **one cycle
  at a time** with `< / >` navigation, an end-month title, the closed date range, and the
  cycle's **spending total**; within a cycle, expenses are sub-grouped by day. This replaces
  the previous calendar-month `Section` grouping.
- **One anchor, shared.** The home cycle and the Insights "This pay period" preset read the
  **same** `Payday` anchor (`NSUbiquitousKeyValueStore`, default 1, range 1–31 — unchanged
  from ADR-0003). Surfaced to the owner as **"Monthly Start Date."** Default 1 keeps a cycle
  identical to a calendar month until the owner changes it.
- **One clamp implementation.** Cycle-boundary math (including the short-month clamp: a 31
  anchor lands on Feb 28/29 and boundaries "walk") lives in a pure `PayCycle` type.
  `DateRangeFilter.payPeriod` delegates its start to `PayCycle`, so there is a single tested
  source of truth. `PayCycle` uses a **half-open** interval `[start, end)`; the Insights
  preset keeps its "spend-so-far" end at `now`.
- **Naming.** A cycle is titled by the month it **ends** in (25 Jul → 24 Aug is "August 2026").
- **Bounds.** `<` pages back to the oldest logged expense's cycle; `>` stops at the **current**
  cycle — no empty future cycles. Launch always opens on the current cycle; paged position is
  not persisted.
- **Spending only.** The per-cycle header shows spending, not income/net — the domain has no
  income concept, and this ADR does not add one.
- **Config surface.** Monthly Start Date is set from a small **Transaction Settings** sheet
  opened from the Expenses toolbar (still one preference; a fuller Settings screen waits for a
  second one, per ADR-0003's reasoning).

## Consequences

- Pay cycle is no longer analytics-only; "This month" is no longer the home's organizing unit.
- No schema change or migration — this is view logic plus the already-synced anchor.
- `PayCycle` is unit-tested in isolation; `DateRangeFilter` behavior (and its tests) are
  unchanged because it now delegates to the same math.
- Still deferred: the list/calendar view toggle, a jump-to-cycle picker, semi-monthly/biweekly
  cycles, and any income/net semantics.
