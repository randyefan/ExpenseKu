# ADR-0013 — Money paid elsewhere is moved back as a reported fact on the expense

Status: Accepted
Date: 2026-10-28
Relates to: ADR-0005 (plan and ledger are separate), ADR-0008 (envelope assignment)

## Context

An Envelope may name the Account its allowance is kept in: Travelling in Jago. On the
trip the owner pays with a credit card for its points, so the Grab is an Expense on CC
Danamon assigned to Travelling. The envelope counts it, since an envelope never reads an
expense's Account. But the money for it is still in Jago while the bill lands on the
card, so next month's salary pays the trip twice, or Jago's leftover drifts away from
the envelope it belongs to.

`CONTEXT.md` keeps "account balances, transfers between accounts, and reconciliation"
out of scope. Moving money from Jago to the card is a transfer between accounts.

Four shapes were considered (`docs/prd/paid-elsewhere.md`):

1. **Log the Grab on Jago.** Quick, and false: the Account detail and Insights would say
   Jago paid.
2. **An Expense for the transfer.** A transfer is not spending; the trip would count twice.
3. **One tick per Account on the envelope.** A Grab logged after the tick leaves it ✓, so
   the row says "moved" while money is still owed.
4. **A flag per Expense saying its money was moved back from the envelope's Account.**

## Decision

**A flag per Expense (4).** `Expense.isMovedFromEnvelope` (schema V7, additive, defaulted
`false`). An expense is **paid elsewhere** when its envelope counts it, the envelope has an
Account, the expense has an Account, and the two differ. The envelope's detail groups
those by Account and reads each group's ◯ / ◐ / ✓ off the flags every time.

- The flag is a fact the owner reports, like Funded. It moves no figure: Sisa, Funded,
  the transfer checklist and the envelope's spent are unchanged.
- Changing the expense's Account or its envelope clears the flag; the move it recorded
  was made for the old ones.
- An expense with no Account counts as paid from the envelope's own.

## Consequences

- The out-of-scope line still holds. The app records *that* the owner moved money, never
  *how much is in* either Account, and creates no Expense and no ledger entry for it.
- A new expense on the card starts unflagged, so its row owes again with nothing to undo.
- A card statement that cuts off mid-trip is settled in rounds by choosing expenses.
- CloudKit Production needs the V7 field deployed before a TestFlight build carries it.
