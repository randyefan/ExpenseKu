# ADR-0008 — An expense assigned to an envelope by hand counts there, not by Category

Status: Accepted
Date: 2026-10-13

## Context

An Envelope counts an expense by its Category (`payday-planning.md` §5.2), and a Category
belongs to at most one envelope per plan. That fits allowances about *what* is bought —
"Hidup (Makan, bensin, emoney saldo)" — and fails for allowances about an *occasion*. A
"Travelling" envelope wants the meals, fuel and hotel of one trip, while the same `Makan`
at home must keep landing in Hidup. No Category can say which meal was on the trip.

Three shapes were considered (`docs/prd/envelope-assignment.md`):

1. **Trip categories** — "Makan Trip" beside "Makan". Splits every Insights chart by
   Category for the sake of the plan.
2. **A date range on the envelope** — automatic, but it takes the home groceries bought
   during the trip and misses the ticket bought a week before.
3. **Assignment by hand** — the expense names its envelope.

## Decision

**Assignment by hand (3).** `Expense` gains an optional `envelope` and an
`isOutsideEnvelopes` flag (schema V4, additive). An expense resolves in this order:

1. created by a Fixed item → its Fixed item, no envelope (unchanged);
2. assigned to an envelope of the plan of its own cycle → that envelope **only**;
3. marked No envelope → no envelope, Outside plan;
4. otherwise → the envelope claiming its Category, if any (unchanged).

An envelope may claim no Category at all. `EnvelopeClaims` is the only implementation of
this order, and every reader — envelope bars, the List split, the plan filter, row tags,
Insights — goes through it.

## Consequences

- The Category stays true, so Insights by Category never sees the plan's bookkeeping.
- One expense still lands in at most one envelope: ADR-0005's no-double-count guarantee
  holds without a new guard.
- An assignment is bound to one plan. Moving the expense's date to another cycle resets
  it in the editor, and an assignment that ends up pointing at another cycle's plan (a
  payday change re-cuts cycles without touching expenses) is ignored rather than trusted.
- Deleting an envelope nullifies its assignments (ADR-0001): those expenses count by
  Category again.
- A new relationship needs a CloudKit Production schema deploy before a build that writes
  it reaches TestFlight.
