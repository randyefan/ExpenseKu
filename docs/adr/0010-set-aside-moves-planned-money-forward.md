# ADR-0010 — A plan may set money aside for a later cycle's envelope

Status: Accepted
Date: 2026-10-17
Relates to: ADR-0005 (plan and ledger are separate), ADR-0009 (paid early)

## Context

The owner wants Rp 20.000.000 for a trip to Japan in December's plan, and to fund it
partly from October's and November's leftover money. December's payday alone is too
heavy. ADR-0009 moves money between plans only behind an expense paid early; here
nothing has been bought, so there is no expense to point forward.

Four shapes were considered (`docs/prd/set-aside.md`):

1. **A Fixed item "Tabungan Jepang"** in each earlier plan. Done creates an Expense, so
   saving is logged as spending, and December still asks for the whole amount.
2. **A savings goal** outside the plans. A running balance, which the app deliberately
   does not keep.
3. **Spreading the envelope automatically** over chosen months. Equal amounts, where the
   owner wants to put in whatever is left over.
4. **A third PlanItem kind that names a later envelope.**

## Decision

**A Set aside kind (4).** `PlanItemKind` gains `.setAside`; `PlanItem` gains an optional
`setAsideTarget` (schema V5, additive) pointing at an Envelope of a later cycle's plan,
with its inverse on the envelope.

- A set-aside item is an ordinary active item of its own plan: it is in Total cost, so
  its own Sisa falls by it with no special case.
- The target plan's Sisa rises by the Σ of the set-aside items targeting its envelopes,
  **uncapped**, from the moment the line exists. Its transfer lines and Group shares
  count each envelope net of what was set aside and paid early, floored at zero.
- A target that is missing, not an envelope, or not in a later cycle is ignored: the
  item still debits its own plan and credits nothing.
- Its ◯/✓ tick is a reported fact and moves no figure. It never creates an Expense.
- Carry-over never copies it.

## Consequences

- ADR-0005 holds: no Expense, nothing in Insights, and Sisa still subtracts no expense.
  Planned money moves between two plans, derived per read from the stored target.
- Uncapped, a December plan can show more Sisa than its income less its cost. The owner
  chose that: money set aside beyond the envelope's plan is free in December.
- Deleting the envelope nullifies the target (ADR-0001); the earlier plans keep their
  lines, warned, so the money the owner already moved is not silently forgotten.
- Every `switch` on `PlanItemKind` gains a case, and readers that assume "not Fixed means
  Envelope" must be checked.
- The CloudKit Production schema owes V5 alongside the V3 and V4 fields still pending.
- A device still on an older build reads the unknown kind as Fixed (`PlanItem.kind`'s
  fallback): the line stays in that plan's Total cost there, with no category and no
  credit to the later plan, until the device updates.
