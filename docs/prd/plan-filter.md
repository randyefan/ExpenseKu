# PRD — Filtering the ledger by plan

Status: Built
Date: 2026-10-03 · design approved and built the same day (flow N)
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the plan whose spending this
separates), `CONTEXT.md` (ubiquitous language), and **`design/ExpenseKu.pen`**, page
`02 · Pages · iPhone`, **Flow N** (moved there from `05 · Proposals` once built). Frame references appear inline as `[→ N2]`.

---

## 1. What this is

Since Flow J, the List lens's header splits the cycle's SPENDING into **Outside plan**
and **From plan**, and every row the plan accounts for carries a violet tag. The owner
can *see* the two halves but cannot look at one alone: on payday the three Fixed rows
(Rp 4.350.000) bury the week's coffee and transport, and the reverse question — "what
has the plan actually spent so far" — means scanning for tags.

This feature lets the owner narrow the List and Month lenses to one half by tapping its
legend entry.

### 1.1 Background — the split rule (Flow J)

Flow J shipped on 2026-09-21 without a PRD. Its rule, which this feature builds on and
does not change:

| An expense is… | when | Row tag |
|---|---|---|
| **From plan** (Fixed) | `Expense.planItem != nil` — a Fixed PlanItem created it | filled violet **Plan** |
| **From plan** (Envelope) | its Category is claimed by an **active** Envelope in the plan of the expense's *own* cycle | outlined violet, the Envelope's name |
| **Outside plan** | neither | none |

The header shows SPENDING (the whole cycle) as the hero, a bar split Outside (accent) /
From plan (violet), and a two-entry legend with each half's figure. The split is drawn
only when From plan is above Rp 0. `PlanOrigins` derives both the tag and the split.

## 2. Goals

1. Show only the Outside-plan expenses of a cycle, or only the From-plan ones.
2. Use the control the owner already reads: the legend entries become the switch.
3. Keep every figure honest: a day header adds up exactly the rows under it, and the
   filtered rows add up to the lit legend figure.

## 3. Non-goals

- **Remembering the filter.** Not across launches, not across cycles (§6).
- **Filtering Search, Person detail or the Plan lens** (§7).
- **Splitting Fixed from Envelope.** "From plan" is one half, both kinds together.
- **Changing the split rule** (§1.1) or the SPENDING hero.

---

## 4. The filter

### 4.1 States and the control

Three states: **All** *(default)* · **Outside plan** · **From plan**. The two legend
entries under the split bar are buttons. `[→ N1]`

| Now | Tap Outside plan | Tap From plan |
|---|---|---|
| All | Outside plan | From plan |
| Outside plan | All | From plan |
| From plan | Outside plan | All |

Both entries are always **outlined chips** (hairline capsule), so they read as buttons
before anything is lit and lighting one moves nothing. The lit chip takes its half's
colour — accent for Outside plan, violet for From plan — as its stroke and wash, and its
dot becomes a checkmark. Nothing dims: the other chip and the whole bar stay at full
strength, and the bar is still the split of the whole cycle. `[→ N1, N2, N4]`

| Rule | |
|---|---|
| "From plan" is Fixed **and** Envelope spending — exactly the §1.1 rule, so the filtered rows sum to the lit legend figure | `[→ N2]` |
| The **SPENDING** hero stays the whole cycle's total while filtered | `[→ N1]` |
| No legend, no filter: a cycle with no From-plan spending looks exactly as today | — an absence |
| While a filter is on, the legend stays drawn **even if From plan falls to Rp 0** (the last plan row deleted), so the filter can always be cleared | — unit test |
| Either entry can be tapped even when its figure is Rp 0; the empty half shows a message (§4.4) | `[→ N3]` |

### 4.2 List lens

The day-grouped list shows only the expenses in the chosen half. `[→ N1, N2]`

- A day with no matching expense is not drawn.
- A day header's total adds up the **visible rows only**.
- Rows are unchanged, tags included.
- Swipe-to-delete deletes the swiped row.

### 4.3 Month lens

Month's header gains the same split bar and legend as List, **whether or not a filter is
on**, under the same Rp 0 rule (§1.1). `[→ N4]` While filtered: `[→ N5, N6]`

- Day cells show the filtered half's day totals; a day with none is blank.
- A cell's weight is measured against the **filtered half's** heaviest day, not the
  whole cycle's.
- The day list under the grid shows the selected day's filtered rows, and its header adds
  up those rows.
- The default selected day is today when the cycle owns it, else the last day **with
  filtered spending**, else the cycle's last day — the existing rule run on the filtered
  half.

### 4.4 Empty half

The message names the half, in the legend's own words, on the existing
`InlineMessageCard`.

| Case | Title | Detail | Frame |
|---|---|---|---|
| List or Month, nothing in the half this cycle | **Nothing outside the plan** / **Nothing from the plan** | No expenses outside the plan in 31/07/2026 ~ 30/08/2026. | `[→ N3]` |
| Month, nothing in the half on the selected day | **Nothing from the plan today** / **… on Sun, 2 August** | Tap From plan again to show every expense. | `[→ N6]` |

### 4.5 The filter pill

While a filter is on, a **PlanFilterPill** floats above the tab bar, in List and Month,
and stays in place as the content scrolls. It wears the tab bar's glass (fill, stroke,
blur, shadow) so the two read as one floating layer; the half's colour appears only in
its leading dot. Then **Outside plan only** / **From plan only**, and ✕ in a small
circle. The whole pill is one button
that clears the filter. It is not drawn while the filter is off, in the Plan lens, or
during Search. `[→ N1, N2, N3, N5, N6]`

The filter never clears itself. An expense that is added, edited or deleted into the
other half drops out of view and the legend figures move; if that empties the half,
§4.4's message shows.

---

## 5. Accessibility

Each legend entry is a button labelled with its name and figure ("Outside plan,
Rp 55.000") and carries the Selected trait while lit. The pill is a button labelled
"Clear filter" with the value "Outside plan only" / "From plan only".

## 6. Lifetime

The filter is **session view state**, held in `ExpensesView` beside the plan sort, above
the lens `.id()`, never stored.

| Event | Filter afterwards |
|---|---|
| App relaunched | All |
| Paging to another cycle (`‹ ›`), and paging back | All |
| Switching List ⇄ Month | kept |
| Switching to Plan and back | kept (Plan ignores it) |
| Searching, then clearing the search | kept |

## 7. Unaffected

- **Plan lens** — its header is SISA and has no legend; the filter waits for List or Month.
- **Search** — all-time results, every expense, tags as today.
- **Person detail** — every expense with that Person, tags as today.
- **The SPENDING hero, the split rule, row tags.**
- **Insights** has a plan filter of its own since `docs/prd/insights-drill-in.md`: the same
  three states and split rule, on Insights and its drill-in. This filter and that one are
  separate view state and never set each other.

---

## 8. Decision log

Settled in a grilling session on 2026-10-03. Entries 13–21 were settled in the design
review of flow N the same day; the first drawing dimmed the unlit half and had no marker,
and the owner sent it back on both.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Three states: **All · Outside plan · From plan** | `N1`, `N2` |
| 2 | "From plan" = Fixed **and** Envelope, the split's own rule | `N2` |
| 3 | The control is the **legend entries** (styling: entry 13) | `N1` |
| 4 | Tapping the lit entry clears; tapping the other switches | — |
| 5 | The SPENDING hero stays the **whole cycle's total** | `N1` |
| 6 | Day headers add up **visible rows only**; empty days disappear | `N1` |
| 7 | An empty half **can be tapped** and shows a message — *owner override*, against disabling a Rp 0 entry and clearing automatically | `N3` |
| 8 | Session-only: relaunch → All, any page → All, lens switch keeps it | — |
| 9 | **Month is filtered too** and its header gains the split legend — *owner override*, against List only | `N4`, `N5` |
| 10 | Empty messages **name the half** in the legend's words | `N3`, `N6` |
| 11 | Month cells **rescale** to the filtered half's heaviest day | `N5` |
| 12 | Its own PRD, which also records Flow J's rule | — |
| D1 | Month shows the split legend whenever the cycle has From-plan spending, filtered or not | `N4` |
| D2 | While filtered the legend stays drawn at From plan Rp 0 | — unit test |
| D3 | No legend, no filter | — |
| D4 | Plan lens ignores the filter and it returns with List/Month | — |
| D5 | Search and Person detail are unaffected | — |
| D6 | The filter never clears itself | — |
| D7 | Month's default day runs on the filtered half | `N6` |
| D8 | Swipe-to-delete works on filtered rows | — simulator |
| D9 | VoiceOver: legend entries are buttons with the Selected trait | — |
| D10 | State lives above the lens `.id()`; `page(to:edge:)` clears it | — |
| 13 | Legend entries are **outlined chips**; the lit one takes its half's colour (stroke + wash) and a checkmark; **nothing dims** — replaces dimming the unlit half | `N1`, `N2` |
| 14 | A **floating pill** marks an active filter and stays while scrolling — against a FocusChip under the toggle | `N1` |
| 15 | The pill wears the **tab bar's glass**; the half's colour shows only in its dot | `N1`, `N6` |
| 16 | The pill reads **Outside plan only / From plan only** | `N1`, `N2` |
| 17 | The pill is **one button** that clears; ✕ is a glyph, not a separate target | `N1` |
| 18 | The pill shows in List and Month, including an empty half; never in Plan or Search | `N3`, `N5` |
| 19 | Chips are outlined **even unfiltered**, so lighting one moves nothing; the header grows ~12pt wherever the split shows | `N4` |
| 20 | An empty filtered day keeps its **`Today · Rp 0`** header above the message | `N6` |
| 21 | No new icons beyond the lit chip's checkmark | — |

---

## 9. Design traceability

Page `02 · Pages · iPhone`, **Flow N · Filter by plan**, after Flow M. Components
`SpendingSplitChip` (private to `CycleHeader`) and `PlanFilterPill` live on
`01 · Design System`, group `Cycle plan`, row `Plan filter`; J1 now uses the chip too. One sample cycle,
August 2026 (31/07 – 30/08, payday 31), "today" Thu 6 August:

| Day | Expense | Amount | Half |
|---|---|---|---|
| Thu 6 Aug | Transport · Grab home · GoPay | 30.000 | Outside |
| Wed 5 Aug | Makan · Lunch · Cash · Tarisa | 45.000 | From plan (Hidup) |
| Sun 2 Aug | Makan · Dinner · GoPay · Fadil | 120.000 | From plan (Hidup) |
| Sun 2 Aug | Kopi · Morning coffee · Cash | 25.000 | Outside |
| Fri 31 Jul | Kos · BCA | 2.500.000 | From plan (Plan) |
| Fri 31 Jul | Cicilan Rumah · BNI | 1.500.000 | From plan (Plan) |
| Fri 31 Jul | Internet · IndiHome · BCA | 350.000 | From plan (Plan) |

SPENDING Rp 4.570.000 · Outside plan Rp 55.000 · From plan Rp 4.515.000.

| Frame | Covers |
|---|---|
| **N1** · List — Outside plan | §4.1 control and lit chip, hero unchanged, §4.2 visible-row totals, empty days gone, §4.5 pill |
| **N2** · List — From plan | §4.1 Fixed + Envelope together |
| **N3** · List — Outside plan, empty (31 July evening: only the three Fixed rows) | §4.1 Rp 0 entry tappable, §4.4 cycle message |
| **N4** · Month — legend, no filter | §4.3 Month gains the split |
| **N5** · Month — Outside plan, today selected | §4.3 filtered cells, rescaled weight (25k and 30k both heaviest), filtered day list |
| **N6** · Month — From plan, default day (today, empty) | §4.3 filtered cells, default day, §4.4 day message |

### 9.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| Which span the empty-cycle message prints | The cycle's own `rangeText`, as the header and the existing empty states print it — `31/07/2026 ~ 30/08/2026`, not the en dash the first draft wrote | `PlanFilter.emptyCycleDetail`, `CycleLensArea` |
| §6 names paging, but the cycle also moves when the payday changes or the tab reopens on a different cycle | Those clear the filter too; paging clears it inside `page(to:edge:)` like the plan sort, so paging back never brings it back | `ExpensesView` |
| What "the tab bar's glass" is in SwiftUI | The system Liquid Glass, `.glassEffect(.regular.interactive(), in: .capsule)`, the material the iOS 26 tab bar itself uses | `PlanFilterPill` |
| The pill must not cover the last row | It sits in a bottom `safeAreaInset`, so the list scrolls under it and its last row can clear it | `ExpensesView` |
| Buttons in the header share a `List` row with ‹ › | A non-default button style (`.pressableCard`), so a tap fires only the chip it lands on | `SpendingSplitChip` |
| The derivation | Pure and tested on this PRD's own sample cycle, one test per rule | `PlanFilter`, `PlanOrigins.expenses(_:in:matching:)`, `PlanFilterTests` |

