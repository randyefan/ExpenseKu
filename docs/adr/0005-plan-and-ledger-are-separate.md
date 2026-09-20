# ADR-0005 — A plan is not a ledger: PlanItem and Expense are separate, linked

Status: Accepted
Date: 2026-09-20

## Context

The owner keeps a salary-allocation spreadsheet outside the app and wants it inside
(see `docs/prd/payday-planning.md`). Its central column, *Pengeluaran*, holds a money
amount per row — which looks exactly like an `Expense` and is not one. It is money the
owner **intends** to move. An `Expense`, per `CONTEXT.md`, is *"a single record of money
the owner spent."*

Every read path in the app rests on that definition: the home cycle total, the day
sub-groups, `SpendSummary`, every Insights chart, the People leaderboard, and search.
None of them filters on anything but date, because until now every `Expense` was, by
construction, money that had already left.

Three shapes were considered:

1. **One entity, with a status.** `Expense` gains an `isPlanned` flag; a plan is a set of
   not-yet-happened expenses.
2. **Two entities, unlinked.** A plan lives entirely on its own; ticking a row strikes it
   through and nothing reaches the ledger.
3. **Two entities, linked.** `PlanItem` stands alone; completing one creates an `Expense`
   and links the two.

## Decision

**Two entities, linked.**

- `PlanItem` is its own model, owned by a `CyclePlan`.
- Completing a Fixed `PlanItem` creates an `Expense` and stores a link between them.
- Analytics read `Expense` only. A `PlanItem` never contributes to a spending total.
- An `Envelope` PlanItem never creates an `Expense` at all; its `spent` is derived from
  expenses that already exist.

The deciding argument was not implementation cost but meaning. A plan can be **wrong**
(`Tagihan Handphone Ibu` was planned at Rp 280.000 and billed at Rp 407.500) and a plan
can be **abandoned** (`Liburan Saving` sat at Rp 0 for nine consecutive cycles). A single
record cannot hold both an intention and an outcome without lying about one of them.

Option 1 was rejected because it silently revokes the invariant that every `Expense` is
money spent, across more than twenty existing call sites — each of which would have to
remember a filter, and any that forgot would report unspent money as spending. Option 2
was rejected because it makes the owner enter everything twice.

## Consequences

- Planned money can never inflate a cycle total, a chart, or the leaderboard. The
  double-counting class of bug is structurally impossible rather than guarded against.
- Both numbers survive, so **plan vs. actual** is expressible per line — the one thing
  the spreadsheet could never show, and the main reason to move it into the app.
- `Expense` gains an optional link to the `PlanItem` that created it. Per ADR-0001 the
  link nullifies: deleting a `PlanItem` leaves its `Expense` intact as history.
- Deleting an `Expense` returns its `PlanItem` to not-done.
- Envelope accounting needs an exclusion rule: an `Expense` linked to a Fixed `PlanItem`
  is excluded from every envelope, or a completed `Kos` would be counted again inside the
  `Hidup` envelope that shares its Group.
- `CONTEXT.md`'s v1 out-of-scope list loses "budgets/limits" and "recurring expenses";
  both now exist in a restricted, plan-local form.
