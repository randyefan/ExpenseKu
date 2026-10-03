# PRD — Insights drill-in, plan filter and past pay periods

Status: Built
Date: 2026-10-03 · design approved and built the same day (flow O)
Owner: Randy Efan

Companion documents: `docs/prd/plan-filter.md` (the Outside plan / From plan split this
brings to Insights, and its §1.1 rule), `docs/adr/0003-pay-period-preset.md` (the pay
period preset this widens), `CONTEXT.md` (ubiquitous language), and
**`design/ExpenseKu.pen`**: **Flow O** on page `02 · Pages · iPhone` (moved there from
`05 · Proposals` once built), which builds **Flow K**'s option A (Flow K stays on 05 for its
rejected options B and C). Frame references appear inline as `[→ O2]`.

---

## 1. What this is

Insights answers "where did the money go" with two breakdowns, Spend by Category and
Spend by Account, but stops there. Three things are missing:

1. A row cannot be opened. "Makan Rp 280.000" cannot show the expenses behind it.
2. Planned money buries everything else. On payday Kos, Cicilan Rumah and Internet
   (Rp 4.350.000) dwarf the week's coffee, and the question that matters, "what did I
   spend *outside* the plan", has no answer here.
3. Only the current pay period can be shown. "How did July go" needs "This month" in
   the wrong boundaries, or "All time".

This feature makes every breakdown row open a detail screen (Flow K, option A), brings
the Outside plan / From plan split to Insights and that screen, and lets the owner pick
any past pay period.

## 2. Goals

1. Tap a category or account row and see its expenses in the same window.
2. Narrow Insights, and the detail screen, to Outside plan or From plan, with the
   control the owner already knows from the Expenses tab.
3. Open any pay period from the current one back to the oldest expense's.
4. Keep every figure honest: a breakdown adds up to its filtered half, and a detail
   header adds up the rows under it.

## 3. Non-goals

- **Remembering the plan filter.** Not across launches, not across windows (§7).
- **Future pay periods.** Nothing has been spent in them.
- **Filtering the People leaderboard or Person detail by plan** (§8).
- **Changing the split rule** (`plan-filter.md` §1.1) or what a breakdown counts.
- **Tapping Spend over Time bars.** They stay a picture (Flow K, K1).
- **A payday setting in Insights.** It moves out (§5.1); Expenses keeps Monthly Start Date.

---

## 4. Drill-in (Flow K, option A)

Flow K's description is the original spec; this section restates it with the decisions
made since.

### 4.1 Rows open a detail screen

Every row of Spend by Category and Spend by Account is a Button with a trailing chevron
and a pressed wash. Tapping it pushes one detail screen onto the Insights stack. `[→ O1]`

| Row | Detail subject |
|---|---|
| A Category | that Category |
| **Uncategorized** | expenses with no Category, route case `.uncategorized` |
| An Account | that Account |
| **Unassigned** | expenses with no Account, route case `.unassigned` `[→ O11]` |

Uncategorized and Unassigned take the glyph and tint of their Insights row and are never
"removed". A deleted Category or Account shows **Category Removed** / **Account Removed**
`[→ O12]`.

The route holds identifiers, the period chip, the selected pay period and the plan
filter, never models (`PersonExpensesRoute`'s reason).

### 4.2 The detail screen

Top to bottom, in this order: `[→ O4, O5, O7]`

| Part | Content |
|---|---|
| **SpendEntityHeader** | glyph and tint, name, "Category · N expenses · <window>", total, share bar, "X% of what you spent in this window" |
| **Period chips** | the same rail as Insights, seeded from it, free to re-scope |
| **Pay period row** | only while the Pay period chip is on (§5) |
| **Split card** | titled **MAKAN BY PLAN** / **GOPAY BY PLAN**: the split bar and two chips (§6.3) |
| **Narrowed to** | the FocusChip, only while narrowed (§4.3) |
| **Breakdown card** | the other dimension: "Makan by account" / "GoPay by category", rows tappable to narrow |
| **Expenses** | `PersonDayCard`s by day, newest first; a row opens the editor sheet |

- The `<window>` in the header subtitle is the chip label, or the cycle title ("July 2026")
  while the Pay period chip is on.
- The share is the subject's total over the window's total, both after the plan filter
  and the narrowing. With nothing in the window it is not drawn: a share of nothing is
  undefined, not 0% `[→ O10]`.
- The breakdown drops a Rp 0 bucket (Unassigned / Uncategorized), the Insights chart's
  own rule `[→ K8]`, and is hidden when the subject has nothing in the window `[→ O10]`.
- Expense rows are unchanged: Category title, meta line, plan tags. On a Category screen
  the title repeats the Category; that is accepted (§9, decision 17).

### 4.3 Narrowing

Tapping a breakdown row narrows the screen to it. The row takes a check, its siblings
dim, and a **FocusChip** ("Narrowed to · GoPay ✕") appears above the card. Tapping the
checked row or ✕ clears it. The header total, share, split card and list follow the
narrowing. `[→ O6]`

### 4.4 Empty

| Case | What shows | Frame |
|---|---|---|
| The subject has nothing in the window, no filter | header Rp 0 with no share bar, breakdown hidden, EmptyStateView **Nothing in This Window** · "Makan has no expenses in July 2026." | `O10` |
| The plan filter's half is empty | the same, titled **Nothing outside the plan** / **Nothing from the plan** · "Makan has no expenses outside the plan in August 2026." The badge wears the subject's own glyph | `O9` |

The detail sentence uses the window's phrase: `DateRangeFilter.phrase`, or "in <cycle
title>" for a pay period.

---

## 5. Pay periods

### 5.1 The chip and the row

The **This pay period** chip is renamed **Pay period** on Insights and the detail screen.
While it is on, the row under the chips reads **Pay period · <cycle title> ⌄** and is a
Menu of cycles. It **replaces the Payday stepper**, which leaves Insights: the payday is
set in Expenses → Monthly Start Date only. `[→ O1, O2]`

The row is a full-width card: the calendar glyph and **Pay period** leading, the cycle
title in the accent and a ⌃⌄ glyph trailing. The rail scrolls the selected chip to its
centre, as K8 draws.

The People leaderboard and Search keep **This pay period**: they have no cycle menu, so
there it still means the current one.

### 5.2 The menu

| Rule | |
|---|---|
| Lists every cycle from the **current one back to the cycle of the oldest expense**, newest first | `[→ O2]` |
| An empty cycle between two others is listed; a future cycle is not | — unit test |
| The Menu is titled **Pay period**; each item shows the cycle title with its `rangeText` under it; the selected one carries the checkmark | `[→ O2]` |
| With no expenses at all, the menu holds the current cycle alone | — unit test |

### 5.3 The window

| Cycle | Window |
|---|---|
| The current one | `start … now`, as today (ADR-0003's spend-so-far) |
| A past one | `start ..< end`, the whole cycle |

Both use `PayCycle`'s boundaries on `Payday.current`.

### 5.4 Spend over Time

| Rule | |
|---|---|
| The amber bar is the **selected** cycle, not always the current one | `[→ O3]` |
| The window is still the 12 cycles ending at the current one; it slides back only when the selected cycle is older than that, to end at the selected cycle | — unit test |
| Every other preset keeps the current cycle amber | `[→ O1]` |
| A selected cycle with Rp 0 has no bar, so nothing is amber | `[→ O8]` |

---

## 6. Plan filter

### 6.1 States and rule

The same three states as `plan-filter.md` §4.1: **All** *(default)* · **Outside plan** ·
**From plan**, with the same tap table and the same split rule (§1.1), applied to each
expense in **its own cycle's plan** (`PlanOrigins.origin(of:)`). An All-time window
therefore mixes cycles: a Makan lunch in a cycle with a "Hidup" envelope is From plan,
one in a cycle without it is Outside plan.

### 6.2 Insights: the SPENDING card

A new card sits under the chips and the pay period row, above the charts. It wears the
CycleHeader's look (card with the accent's 5% wash) without the ‹ › row. `[→ O1, O3]`

| Rule | |
|---|---|
| **SPENDING** is the window's whole total and stays whole while filtered (`plan-filter.md` decision 5) | `[→ O3]` |
| Under it, the split bar and the two **SpendingSplitChip**s, exactly as in the cycle header | `[→ O1]` |
| No From-plan spending in the window and no filter on: SPENDING only, no bar, no chips | — an absence |
| A filter on keeps the chips drawn even at From plan Rp 0, so it can be cleared | — unit test |
| An empty half can be tapped (`plan-filter.md` decision 7) | `[→ O8]` |

While filtered, everything below the card follows the half:

| Part | Filtered how |
|---|---|
| Spend by Category, Spend by Account | only the half's expenses, ranked and scaled among themselves |
| Spend over Time | each bar is the half's spending **in that bar's cycle** |
| Empty Category / Account chart | the ghost bars, with **Nothing outside the plan in this period.** / **Nothing from the plan in this period.** `[→ O8]` |
| People leaderboard card | unchanged (§8) |

### 6.3 Detail: the split card

A card of its own, under the period chips and the pay period row, holding the split bar
and the two chips for **the screen's subject** (after narrowing), in the window. `[→ O4]`

- A plain card (no wash) titled **<SUBJECT> BY PLAN**, matching "<SUBJECT> BY ACCOUNT".
- The card follows the same show/hide rule as §6.2.
- While filtered, the header total, share, breakdown and list follow the half. The share
  reads **X% of what you spent outside the plan in this window** / **… from the plan …**,
  over the window's half, not its whole. `[→ O4]`
- The detail sets its own filter; going back does not change the Insights filter.

### 6.4 The pill

While a filter is on, the **PlanFilterPill** floats above the tab bar on Insights and on
the detail screen, as in `plan-filter.md` §4.5: one button that clears the filter on the
screen it sits on. `[→ O3, O4]`

---

## 7. Lifetime

All of it is **session view state**, never stored.

| Event | Selected cycle | Plan filter (Insights) | Plan filter (detail) |
|---|---|---|---|
| App relaunched | current cycle | All | — |
| Changing the period chip | kept | **All** | **All** |
| Picking a cycle in the menu | — | **All** | **All** |
| Pay period → another chip → Pay period | the same cycle | All | All |
| Switching tabs and back | kept | kept | kept |
| Payday changed in Expenses | current cycle | kept | kept |
| Pushing a detail screen | carried | carried | — |
| Popping back to Insights | Insights' own | Insights' own | — |
| Narrowing or clearing a narrowing | — | — | kept |

The narrowing is kept when the window changes.

## 8. Unaffected

- **People leaderboard and Person detail** — no plan filter, chip still "This pay period".
- **Search and the Expenses tab** — unchanged.
- **The split rule, row tags, SpendSummary's grouping.**

---

## 9. Decision log

Settled in a grilling session on 2026-10-03; entries 19–27 are the design calls the owner
approved with flow O the same day. Flow K's own decisions (option A, K1–K4,
K8–K11) were settled on 2026-09-25.

| # | Decision | Drawn in |
|---|---|---|
| 1 | The plan filter lives on **Insights and the detail screen**; it is carried into the detail and can be changed there | `O3`, `O4` |
| 2 | Insights' control is a new **SPENDING card** with the split bar and chips | `O1` |
| 3 | Past pay periods are picked from a **Menu of cycles** — *owner override*, against ‹ › in the SPENDING card | `O2` |
| 4 | The menu row **replaces the Payday stepper** | `O1` |
| 5 | The chip reads **Pay period** on Insights and detail; leaderboard and Search keep "This pay period" | `O1` |
| 6 | The menu lists **current → oldest expense's cycle**, newest first, empty cycles included, no future | `O2` |
| 7 | Spend over Time **follows the plan filter**, per cycle | `O3` |
| 8 | The amber bar marks the **selected** cycle; the 12-cycle window slides only when needed | `O3` |
| 9 | A window with no From-plan spending shows SPENDING only (Flow J rule) | — |
| 10 | The **pill** appears on Insights and the detail screen | `O3`, `O4` |
| 11 | On the detail screen the split is a **card of its own under the chips** — *owner override*, against folding it into the header | `O4` |
| 12 | The detail header's total and share **follow the filter** | `O4` |
| 13 | Changing the chip or the cycle **resets the plan filter to All** — *owner override*, against keeping it | — |
| 14 | The selected cycle lasts **the session**, across chip changes and tab switches | — |
| 15 | An empty chart says **Nothing outside / from the plan in this period.** on the ghost bars | `O8` |
| 16 | **Uncategorized** opens a detail screen too (`.uncategorized`) | — |
| 17 | Detail rows stay as Flow K draws them: Category title, plan tags | `O5` |
| 18 | Its own PRD; `plan-filter.md` §7 now points here | — |
| D1 | Insights' SPENDING hero stays whole while filtered | `O3` |
| D2 | The detail split card describes the subject after narrowing | `O6` |
| D3 | A past cycle is its whole span; the current one ends at now | — unit test |
| D4 | The detail has its own cycle menu, seeded from Insights; its changes do not flow back | `O4` |
| D5 | Narrowing survives a window change | — |
| D6 | A payday change returns the selected cycle to the current one | — |
| D7 | An empty half on the detail screen follows K9 with the half's title | `O9` |
| D8 | Leaderboard, Person detail, Search and Expenses are unaffected | — |
| D9 | Menu items: title over `rangeText`, a checkmark on the selected one | `O2` |
| 19 | The pay period row is a full-width card, the cycle title in the accent with ⌃⌄ | `O1` |
| 20 | The menu is titled **Pay period** and anchored to the row's trailing edge | `O2` |
| 21 | The SPENDING card wears CycleHeader's 5% accent wash, without ‹ › | `O1` |
| 22 | The detail split card is titled **<SUBJECT> BY PLAN**, plain card | `O4` |
| 23 | Detail order: header · chips · pay period row · split card · Narrowed to · breakdown · days | `O6` |
| 24 | The empty detail's badge wears the subject's glyph | `O9` |
| 25 | A Rp 0 selected cycle has no bar and nothing amber | `O8` |
| 26 | The rail centres the selected chip | `O1` |
| 27 | The People leaderboard card stays last and unfiltered | `O3` |

ADR-0003 deferred "Last pay period" and placed the payday stepper in Insights; this
feature does both differently. Its anchor and period math are unchanged.

---

## 10. Design traceability

Page `02 · Pages · iPhone`, **Flow O · Insights drill-in, plan filter and pay periods**,
after Flow N. Components `PayPeriodMenuRow`, `InsightsSpendingCard`, `SpendSplitCard` and
`SpendBreakdownCard` live on `01 · Design System`, group `Insights`, row `Pay period & plan
split`; `ProportionRow · Tappable`, `SpendEntityHeader` and `FocusChip` sit in the row before
it. Flow C's C1 and C2 now draw the Pay period chip, the cycle menu and the SPENDING card.
One sample, payday 31, "today" Thu 6 August 2026:

| Cycle | Day | Expense | Account | Amount | Half |
|---|---|---|---|---|---|
| June 2026 (31/05 ~ 29/06) | Sun 31 May | Kos | BCA | 2.500.000 | From plan (Plan) |
| | Sun 31 May | Cicilan Rumah | BNI | 1.500.000 | From plan (Plan) |
| | Sun 31 May | Internet · IndiHome | BCA | 350.000 | From plan (Plan) |
| July 2026 (30/06 ~ 30/07) | Tue 30 Jun | Kos | BCA | 2.500.000 | From plan (Plan) |
| | Tue 30 Jun | Cicilan Rumah | BNI | 1.500.000 | From plan (Plan) |
| | Tue 30 Jun | Internet · IndiHome | BCA | 350.000 | From plan (Plan) |
| | Sun 12 Jul | Makan · Lunch | Cash | 60.000 | Outside |
| | Sat 18 Jul | Transport · Parkir | — | 10.000 | Outside |
| | Mon 20 Jul | Makan · Dinner | GoPay | 55.000 | Outside |
| | Sat 25 Jul | Kopi · Iced latte | GoPay | 40.000 | Outside |
| August 2026 (31/07 ~ 30/08) | Fri 31 Jul | Kos | BCA | 2.500.000 | From plan (Plan) |
| | Fri 31 Jul | Cicilan Rumah | BNI | 1.500.000 | From plan (Plan) |
| | Fri 31 Jul | Internet · IndiHome | BCA | 350.000 | From plan (Plan) |
| | Sun 2 Aug | Kopi · Morning coffee | Cash | 25.000 | Outside |
| | Sun 2 Aug | Makan · Dinner | GoPay | 120.000 | From plan (Hidup) |
| | Wed 5 Aug | Makan · Lunch | Cash | 45.000 | From plan (Hidup) |
| | Thu 6 Aug | Transport · Grab home | GoPay | 30.000 | Outside |

Only August's plan has the **Hidup** envelope (claiming Makan), so Makan is Outside plan
in July and From plan in August.

| Window | SPENDING | Outside plan | From plan |
|---|---|---|---|
| June 2026 | 4.350.000 | 0 | 4.350.000 |
| July 2026 | 4.515.000 | 165.000 | 4.350.000 |
| August 2026 (to 6 Aug) | 4.570.000 | 55.000 | 4.515.000 |
| All time | 13.435.000 | 220.000 | 13.215.000 |

| Frame | Covers |
|---|---|
| **O1** · Insights — August, All | §4.1 chevrons, §5.1 Pay period chip and row, §6.2 SPENDING card |
| **O2** · The cycle menu | §5.2 contents and order, D9 |
| **O3** · Insights — July, Outside plan | §5.3 whole past cycle, §5.4 amber on July, §6.2 filtered charts and trend, hero whole, §6.4 pill |
| **O4** · Makan — from O3 (July, Outside plan carried) | §4.2 parts, D4 menu, §6.3 split card, share over the half, pill |
| **O5** · Makan — All time, All | §6.1 mixed cycles: 115.000 outside, 165.000 from plan; decision 17 rows |
| **O6** · Makan — All time, Outside plan, narrowed to GoPay | §4.3 FocusChip, D2 split of the narrowed subject |
| **O7** · GoPay — August | §4.2 the account variant, breakdown by category |
| **O8** · Insights — June, Outside plan (Rp 0) | decision 15 empty charts, Rp 0 chip tappable, trend still drawn |
| **O9** · Makan — August, Outside plan, empty | §4.4 / D7 |

| **O10** · Makan — empty window (Flow K's K9, own sample) | §4.4 first row |
| **O11** · Unassigned (K10) | §4.1 `.unassigned` |
| **O12** · Category removed (K11) | §4.1 removed state |

### 10.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| The current cycle ends at *now*, so recomputing the window on every render moved the fetch's upper bound and remounted the charts on each plan-filter tap | Insights holds its own `now`, refreshed when the chip or cycle changes and when the tab reappears | `InsightsView` |
| How a closed range expresses a past cycle's `start ..< end` | `start ... end − 1 ms`, so the next cycle's first instant is never counted | `InsightsWindow.range` |
| An inline Picker in the cycle Menu drops the **Pay period** title O2 draws | Toggles in a titled `Section`, PlanSortMenu's fix; each item's second `Text` is the iOS subtitle | `PayPeriodMenuRow` |
| Spend over Time drops cycles before the first one with spending, so it draws fewer than twelve bars on a young store | Kept: the existing `byPayPeriod` rule. A selected cycle before the first spend has no bar, the same as rule 25 | `SpendSummary.byPayPeriod` |
| Breakdown rows are grouped by name, but a drill-in needs an entity | The row carries the id of its first expense's Category / Account; the drill-in matches by id. Names are unique by ADR-0002 | `CategorySpend.subject`, `AccountSpend.subject` |
| Narrowed to a bucket the filter then empties | The FocusChip resolves its name from the entity, not the breakdown, so it can still be cleared; the empty message names both ("Makan · GoPay has no expenses …") | `SpendEntityView` |
| What a deleted Account shows | **Account Removed** · "This account was deleted, so there is nothing left to show here.", mirroring K11 | `SpendEntityView` |
| Resolving ids without the crash `model(for:)` has on a deleted id | Shared with PersonExpensesRoute as `ModelContext.existingModel(for:)` | `ModelContext+Existing` |
| The split legend was private to CycleHeader | `SpendingSplitView`, `SpendingSplitBar` and `SpendingSplitChip` are shared views in `Features/Plan`; the bar leaves its 2pt gap only when both halves have spending | `SpendingSplitBar` |
| How Insights learns of a payday changed in Expenses | It re-reads `Payday.current` on appear and returns the chosen cycle to the current one (D6) | `InsightsView.refresh` |
| The derivation | Pure and tested on this PRD's own sample, one test per rule | `InsightsWindow`, `PayPeriodChoices`, `SpendSubject`, `SpendEntityDetail`, `PlanOrigins.expenses(_:matching:)` / `split(_:)`, `InsightsDrillInTests` |
