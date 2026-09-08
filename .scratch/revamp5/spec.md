# ExpenseKu — Person detail revamp

The drill-down behind a People-leaderboard row, left behind by the home revamp.

## What broke

`ExpenseRow` was rebuilt for the home screen to live *inside* a day ledger card: it
lost its own card and gained `.padding(.vertical, 10)`. `PersonExpenseCard` still
wrapped each single row in `.cardStyle()`, so this screen went back to the
card-per-row scatter the home revamp deleted — 3 expenses filling a whole screen.

Verified in `.scratch/revamp/shots/person-before.png`:

1. Card-per-row scatter, doubled padding.
2. The date orphaned on its own line, indented `Metric.iconSize + 12` (44) while the
   icon is now `rowIconSize` (38) — 6pt out.
3. Rows dead: on home every row opens the editor, here nothing happens.
4. Zero motion. The screen hard-cuts in.
5. The inherited filters render as dead grey text where the leaderboard has chips.

## Research (Appllama)

Splitwise (`458023433`, $600K/mo), Groups flow — `Group Expense List`, `Group Overview Empty`.

| Pattern | Adopted as |
|---|---|
| Patterned hero band carrying the subject's identity, title inside it | Hero washed with **the companion's own tint** (`Person.colorHex`, already there since the entity-editor revamp) |
| Pill rail of lenses under the hero, clipped at both edges | The **period rail is live here**, not inherited text — `PeriodFilterChips` on `ChipRail` |
| Date column on the left, rows flush in one list, no per-row cards | The home's **day ledger cards** — same `DayGroupHeader` + `ExpenseRow` the Expenses tab uses |

Pattern, never pixels: no green, no mascot, no FAB, no patterned texture. Amber stays
the one accent; the companion's tint is identity, not action.

## The screen

1. **Hero band** — avatar, name, rolling total, `N expenses · range`, and a share
   meter ("x% of your spend in this period") growing with `Motion.chartGrow`.
2. **Period rail** — re-scopes the screen. The route's range seeds it; category and
   account narrowing inherited from the leaderboard stays as a quiet caption.
3. **Day ledger cards** — one card per day, `DayGroupHeader` above it, rows inside
   separated by hairlines, each row tapping through to the editor.
4. **Motion** — reveal cascade retriggered by the range, rolling total, growing meter,
   `.pressableRow` wash, selection haptics.

## Cost of the live rail

`@Query` fixes its predicate at init, so a range the screen can change cannot bound
the fetch. The query goes unbounded and the range is sliced in memory — which is
already the worst case when arriving from an All-time leaderboard. In exchange the
range switch needs no remount, so the total rolls and the cascade replays.

## Guardrails

Unchanged from `.scratch/revamp2/spec.md`: spending only, one amber accent, Plus
Jakarta Sans, cards 16 / inner rows 12 / controls capsule, no emoji in chrome, no
gradients. Attribution stays full-amount-to-each-companion.
