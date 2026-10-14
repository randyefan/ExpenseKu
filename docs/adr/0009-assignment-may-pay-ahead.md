# ADR-0009 — An assignment may point forward, to a later cycle's envelope

Status: Accepted
Date: 2026-10-14
Amends: ADR-0008 (its "an assignment is bound to one plan" consequence)

## Context

ADR-0008 lets the owner assign an expense to an envelope by hand, and binds that
assignment to the plan of the expense's own cycle: an assignment pointing at any other
cycle's plan is ignored. That breaks on the first real trip. Payday is the 25th; the
"Travelling" envelope for a trip on 27 October lives in November's plan (25 Oct – 24 Nov);
the train ticket is bought on 14 October. Its date puts it in October, whose plan has no
Travelling, so the ticket can only land by Category — at worst inside October's Hidup.

Four answers were considered (`docs/prd/envelope-assignment.md` §4.10):

1. **Change the expense's date** to fall in November. The ledger then lies about when
   the money left.
2. **No envelope, and lower November's Travelling by hand.** Two edits that drift apart,
   and Travelling's bar never shows the ticket.
3. **A Fixed item in October's plan** for the ticket. It plans in October money that the
   owner budgeted for November.
4. **Let the assignment point forward** to a later cycle's envelope.

## Decision

**Forward assignment (4).** The resolver (`EnvelopeClaims`) gains one row between
"assigned in its own cycle" and "No envelope":

- assigned to an envelope of a **later** cycle's plan → **paid early**: that envelope
  counts it in its own cycle; in the expense's own cycle it counts in **no** envelope and
  is Outside plan, never falling back to its Category's claimant.

An assignment to an **earlier** cycle's plan is still ignored, as ADR-0008 said. The
expense keeps its date, so the ledger, cycle totals and Insights are untouched. Only plans
that already exist are offered, and only cycles that have not ended.

No schema change: `Expense.envelope` (V4) already holds the link, and the envelope's
cycle is derived from `envelope.plan.cycleStart`.

## Consequences

- Still counted once (ADR-0005): row 3 wins over the Category claim, so the ticket is
  never in October's Hidup *and* November's Travelling.
- A cycle's envelope bars now read expenses dated **before** the cycle. `PlanContents`
  and the pickers can no longer feed `EnvelopeSpend` the cycle's own expenses alone; they
  add the envelopes' paid-early expenses.
- A cycle's From plan figure (dated expenses only) and its envelopes' spent can differ by
  the paid-early amount; the envelope row's caption names it.
- Deleting the envelope nullifies the assignment (ADR-0001) and the expense counts by
  Category again in its own cycle.
- A payday change that re-cuts cycles may turn an own-cycle assignment into a paid-early
  one or an ignored backward one; neither double-counts.

## Amendment — flow U (2026-10-14)

Counting the ticket only in Travelling's bar left both plans' Sisa untouched, so the
money was set aside twice: free in October's Sisa, still owed by November's payday. A
paid-early expense now **moves its amount between the two plans**: the own cycle's Sisa
falls by it in full; the envelope's cycle's Sisa rises by it, capped at the envelope's
planned amount. Each side shows it as a reconciling row, so Total cost keeps meaning
Σ planned. Transfer lines and Group shares count the envelope net of the credit. Drift
is unchanged by the owner's choice: an envelope's whole overspend stays in its own
cycle's Over plan so far (`docs/prd/envelope-assignment.md` §4.10.10).

ADR-0005 still holds — Sisa subtracts no expense of its own cycle. The paid-early row
moves *planned* money between two plans; it is derived per read from the assignments and
never stored.
