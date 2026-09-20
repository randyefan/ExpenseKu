# ADR-0007 — Auto plan items create their own expenses on a due day

Status: Accepted
Date: 2026-09-20

## Context

The spreadsheet's *Done* column holds three values, not two: ☐, ☑, and the word **Auto**.
`Auto` replaces the checkbox on autodebits and subscriptions — `Cicilan Rumah BNI`,
`Gym membership`, `Netflix`, `Vidio`, `Apple Service`, `Cicil ke Kartu Kredit`. The owner
never ticks those rows, because nothing is required of them.

`Auto` does **not** mean "exclude from the transfer list" — verified: `ke BNI
Rp 7.706.000` is `Cicilan Rumah BNI`, an Auto row. The transfer line means *"make sure
this account holds enough for the debit to clear."*

If Auto items never produced an `Expense`, the ledger would lose Rp 7.706.000 every
cycle — the single largest line in the entire spreadsheet. So the expense must exist. The
question was who creates it and when.

ADR-0005's sibling decision put a **confirmation sheet** on manual completion, precisely
because planned amounts drift from real ones. The recommendation here was consistent with
that: treat `Auto` as a badge only, still confirmed by hand. The owner chose full
automation instead. The spreadsheet has no date column of any kind across nine cycles, so
the due day is a genuinely new concept introduced to serve this.

## Decision

- A `PlanItem` may carry an optional **due day** — a day-of-month, not a date, so that
  carry-over reproduces it without re-entry. Days 29–31 clamp to the end of short months,
  reusing the `PayCycle` clamp already built for the `Payday` anchor.
- A `PlanItem` marked `Auto` **with** a due day creates its `Expense` automatically, at
  the planned amount, without confirmation. Marked `Auto` **without** one, it never fires
  and must be completed by hand.
- Every automatically created `Expense` is flagged **needs review** until the owner
  clears it. The Plan lens surfaces one dismissible line — *"3 Auto items posted — check
  the amounts"* — clearable in a single tap.
- On non-Auto items the due day is a reminder only and changes no behaviour.

## Consequences

- **Materialisation is lazy, not scheduled.** iOS does not run the app in the background
  for this, so an Auto expense appears the first time the app is opened after its due day
  passes. Five days away produces five expenses at once on the next launch; the review
  notice must read sensibly in that case.
- **The app can record money that never moved.** A failed autodebit, or a changed amount
  — `Cicil ke Kartu Kredit` ran Rp 6.751.000 in February and Rp 4.700.000 in August —
  produces a confidently wrong `Expense`. The needs-review flag is the only defence, and
  it is a prompt, not a guarantee: an owner who dismisses it without looking has silently
  corrupted the cycle total, the Group percentages, and Sisa.
- The app now holds two different answers to "how careful are we about a planned amount":
  confirmed for manual items, unconfirmed for Auto ones. The needs-review flag is what
  keeps that defensible; removing it would leave the inconsistency bare.
- Materialisation must be **idempotent**. It runs on launch and potentially on CloudKit
  remote change, on more than one device, against a store that cannot enforce a unique
  constraint (ADR-0002) — the same duplication hazard `Person.reconcileMe` already guards
  against. The `PlanItem`→`Expense` link is what makes "already materialised" checkable.
