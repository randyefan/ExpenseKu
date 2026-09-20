# ADR-0006 — Person widens to include beneficiaries; the leaderboard mixes both

Status: Accepted
Date: 2026-09-20
Amends: the Person definition in `CONTEXT.md`

## Context

`CONTEXT.md` has defined `Person` narrowly and deliberately since v1:

> A Person is **who I was with**, *not* who I paid on behalf of. There is no
> bill-splitting or beneficiary tracking.

The People leaderboard is built on exactly that reading: it answers *"who did I spend the
most time spending money with."*

The salary-allocation spreadsheet does not respect that line. Its second-largest Group,
`Lovely Support`, is entirely money sent **to** named people:

```
Kirim buat Ibu              Rp  1.500.000
Tarisa Needs                Rp  1.500.000
THR fara-eja-tarisa         Rp  3.000.000
Traktir Bude Jogja Bukber   Rp  3.187.000
Kasih farah uang liburan    Rp 20.000.000
```

In March 2026 that Group was **53,91% of total income**. These are transfers; the owner
was not present for most of them.

Three options were weighed: keep `Person` narrow and let the `Group` carry the
who-it-was-for question; introduce a separate `Beneficiary` entity so both questions stay
answerable independently; or widen `Person` to cover both.

The recommendation put to the owner was to keep `Person` narrow for v1 and note
`Beneficiary` as a strong v2 candidate. The owner chose to widen `Person`, and then — when
asked how the leaderboard should separate the two meanings again (a Group filter, an
automatic exclusion, two leaderboards, or none) — chose to let it mix.

## Decision

- **`Person` now means anyone an expense is associated with**: a companion the owner was
  with, or a recipient the owner sent money to.
- A `PlanItem` carries `People`, and passes them to the `Expense` it creates.
- The **People leaderboard is not split, filtered, or qualified.** It ranks total spend
  associated with each Person, from both meanings combined.
- No `Beneficiary` entity is introduced.

## Consequences

- The leaderboard's question changes from *"who do I spend the most time with"* to
  *"who is the most money associated with."* Recurring transfers will dominate it —
  `Kirim buat Ibu` alone is Rp 1.500.000 every cycle, against jajan-sized companion
  spending. This is the accepted trade, not an oversight.
- The narrow question is **not recoverable** from the data afterwards without a new
  axis. Recovering it later means adding a `Beneficiary` entity or a per-expense
  distinction, and re-tagging history.
- The spend-attribution rule is unchanged: full amount to each Person on an expense, a
  per-person ranking rather than a sum.
- `CONTEXT.md` is amended: the Person, Companion, and People-leaderboard entries, and the
  "bill-splitting/beneficiary tracking" line in the v1 out-of-scope list.
- No schema change is needed on `Person` itself; only `PlanItem` gains the relationship.
