# Spec: Pay-period filter preset

Status: resolved

## Resolution

- 2026-08-09: Implemented. `DateRangeFilter` gained a `.payPeriod` case (ordered right
  after `.thisMonth`) and a `range(now:calendar:payday:)` overload — pure, with short-month
  clamping and end-at-now. Anchor lives in `Payday` (`NSUbiquitousKeyValueStore`, default 1,
  clamped 1–31). `InsightsView` reveals an inline "Payday" stepper only when the pay-period
  preset is selected and writes back to the store; `PeopleLeaderboardView` threads
  `Payday.current` into its shared filter. Tests in `DateRangeFilterTests` cover payday=1
  equivalence, the prior-month roll, short-month clamp, on-payday, and end-at-now. Verified
  **BUILD SUCCEEDED** and **TEST SUCCEEDED** on the iPhone 17 (iOS 26.5) simulator.

Let the owner view Insights over **their pay cycle** instead of the calendar month.
Add a **"This pay period"** preset to the Insights date filter, anchored to a
configurable **payday** (day-of-month). Single-user, analytics-only — no budgets,
no income, no persistence beyond one preference value.

See `CONTEXT.md` (repo root) for the ubiquitous language and `docs/adr/0003-pay-period-preset.md`
for the storage + period-math decision.

## Scope (decided)

- **Single owner, one anchor.** One configurable payday for the owner — not multi-user,
  not a moving "last working day." A fixed day-of-month integer.
- **Insights preset only.** Sits in `DateRangeFilter` beside "This month"; nothing else
  in the app is redefined. Not the app's primary grouping (a possible future).
- **Monthly cycle only.** Day-of-month anchor. Semi-monthly / biweekly are explicitly
  not modeled until needed.
- **v1 addition.** Self-contained: a pure preset + one synced preference. No budget semantics.

## Data / config

- **Payday anchor** stored in **`NSUbiquitousKeyValueStore`** (iCloud key-value), not
  SwiftData. Rationale in ADR-0003: a SwiftData "settings singleton" can silently
  duplicate across devices (no unique constraint — the ADR-0002 trap), so a KV-store
  preference is the right home for one integer that should still sync.
- **Default = 1**, so "This pay period" is identical to "This month" until the owner
  changes it — never surprising, never broken out of the box.
- Valid range **1–31**.

## Period math

- `DateRangeFilter.range(now:calendar:)` grows an anchor parameter →
  `range(now:calendar:payday:)`. The anchor is **threaded in as a pure parameter**;
  the enum never reads `NSUbiquitousKeyValueStore` itself (keeps the analytics layer
  pure + unit-testable, matching how aggregation is already isolated from UI). Every
  non-pay-period case ignores the parameter.
- **This pay period** = `start ... now`, where `start` is the most recent payday
  **on-or-before `now`**.
  - Ends at **now** (spend-so-far), matching the existing `thisMonth` semantics — not
    the full payday-to-day-before-next-payday span.
- **Short-month clamp:** if the payday exceeds the month's length (e.g. 31 in February),
  clamp to the **last valid day** of that month.

## UI

- New case in `DateRangeFilter`, label **"This pay period"** (parallel to "This month").
- **Inline stepper** in `InsightsView`: when "This pay period" is selected, reveal a
  small **"Payday: [ 25 ]"** stepper (1–31) right in the filter area — no Settings screen.
  The View reads/writes the KV-store value and passes it into `range(payday:)`.
  - Promote to a dedicated Settings screen only when a *second* preference appears.
- **"Last pay period"** is out for v1 — trivial follow-on when comparison is wanted.

## Out of scope (this feature)

Multi-user / per-person paydays · semi-monthly or biweekly cycles · "last working day"
weekend/holiday shifting · "Last pay period" comparison · global redefinition of "month" ·
pay-period as the app's primary lens · any budget/income semantics.

## Tests

- `DateRangeFilter.range(payday:)` for: payday=1 equals `thisMonth` start; payday mid-month
  before vs after today's date-of-month (start rolls to prior month); payday=31 in a 30/28-day
  month clamps to last day; end always == `now`.
