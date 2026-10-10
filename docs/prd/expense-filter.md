# PRD — Filtering expenses by Category, Group, Account and Person

Status: Built
Date: 2026-10-10 · design approved and built the same day (flow P)
Owner: Randy Efan

Companion documents: `docs/prd/plan-filter.md` (the Outside plan / From plan filter this
combines with), `docs/prd/insights-drill-in.md` (the Insights window and the drill-in this
filter reaches), `CONTEXT.md` (ubiquitous language), and **`design/ExpenseKu.pen`**, page
`02 · Pages · iPhone`, **Flow P** (moved there from `05 · Proposals` once built; the two
marks not chosen stay on 05). Frame references appear inline as `[→ P3]`.

---

## 1. What this is

The Expenses tab (the List and Month lenses) and Insights can be narrowed by **when**
(the cycle, the period chip) and by **plan** (Outside plan / From plan), but not by
**what**, **what for**, **paid from** or **with whom**. "How much went on Makan and Kopi
this cycle", "what did I pay with GoPay", "what did I spend with Fadil and Tarisa" each
mean scanning rows by eye, or a detour through the People leaderboard.

This feature adds one **Filter** to both screens: any number of Categories, Groups,
Accounts and People, chosen in a sheet, applied live.

## 2. Goals

1. Narrow the List and Month lenses, and Insights, to the expenses of chosen Categories,
   Groups, Accounts and People.
2. Read the filtered total at a glance, with the whole beside it.
3. Combine with the plan filter, so "Makan outside the plan" is two taps.
4. Keep every figure honest: the hero, the split chips, day headers and charts add up the
   same filtered set.

## 3. Non-goals

- **The Plan lens.** It lists PlanItems, not Expenses (§7).
- **Search.** It keeps its own Category and Period chips (§9).
- **The People leaderboard and Person detail.** They have Category / Account menus of
  their own (§9).
- **Remembering the filter across launches** (§8).
- **Saved filters, negation ("not Kos"), or OR between dimensions.**

---

## 4. The filter

### 4.1 Dimensions and matching

Four dimensions, always in this order: **Category · Group · Account · Person**.

| Dimension | An expense matches a chosen value when… | Its empty value | …matched by |
|---|---|---|---|
| **Category** | `expense.category` is that Category | **Uncategorized** | `category == nil` |
| **Group** | its Category belongs to that Group | **No group** | no Category, or a Category with no Group |
| **Account** | `expense.account` is that Account | **Unassigned** | `account == nil` |
| **Person** | that Person is among `expense.people` | **No one** | `people` is empty |

| Rule | |
|---|---|
| Several values in one dimension combine with **OR** (Makan *or* Kopi; Fadil *or* Tarisa) | `[→ P3, P7]` |
| Dimensions combine with **AND** (Makan *and* GoPay) | `[→ P6]` |
| A dimension with nothing chosen is **All** and does not narrow | `[→ P1]` |
| Group and Category are separate dimensions: Group = Housing & Living with Category = Kopi, Kos leaves only Kos | — unit test |
| An impossible combination is allowed and shows §4.6's message | `[→ P6]` |
| The filter combines with the plan filter by **AND**; neither resets the other | `[→ P4]` |

The filter is held as **identifiers**, never live models. A chosen entity that is deleted
drops out of the filter: its dimension falls back to All if nothing else is chosen there.

### 4.2 The Filter button

A toolbar button, **Filter** (`line.3.horizontal.decrease`), on the Expenses tab beside
Monthly Start Date at the leading edge `[→ P3]`, and on Insights and the drill-in at the
trailing edge `[→ P7, P8]`.

| State | Look |
|---|---|
| No filter | the outlined glyph, secondary tint |
| Filter on | the glyph and the glass stroke in the accent, with the number of **active dimensions** as a badge on its top-trailing corner `[→ P3, P6]` |

It is not drawn when the store has no expenses (Search's rule), nor in the Plan lens, nor
during Search.

### 4.3 The sheet

Tapping Filter opens a sheet titled **Filter**, with **Clear All** (leading, disabled when
nothing is chosen) and **Done** (trailing). `[→ P1]`

- The root lists four rows, one per dimension, in §4.1's order. Each shows the dimension
  name leading and its current value trailing, then a chevron: **All**, one name, two names
  ("Kopi, Makan"), or two names and a count ("Kopi, Kos +2"), always in checklist order.
- Tapping a row pushes its **checklist** inside the sheet. `[→ P2]`
- The checklist lists **every** entity of that dimension, whatever the window, sorted by
  name (`localizedStandardCompare`), with the empty value (§4.1) **last**, under a divider.
- A row is a Button; tapping it toggles its checkmark. **Each tap applies at once** — the
  screen behind the sheet follows. There is no Cancel and no Apply.
- The sheet opens at `.medium` and grows to `.large` when a checklist is pushed. The
  checklist keeps **Done** trailing and ‹ leading; under the lists sits a text button,
  **Clear Category** / **Clear Group** / **Clear Account** / **Clear Person**, that
  empties that dimension alone. `[→ P2]`
- The empty value sits in a card of its own under the main list; Uncategorized wears a
  dashed-circle glyph in a neutral wash. `[→ P2]`
- Under the root rows, one help line: *Choices in one row match any of them. Rows
  combine: an expense shows only if it matches every row.* `[→ P1]`
- Done closes the sheet. Clear All empties every dimension and leaves the sheet open.

### 4.4 The filter pill

While a filter is on, a glass **pill** floats above the tab bar beside the lit button, on
the Expenses tab (List and Month), on Insights and on the drill-in. It is the
**PlanFilterPill** shape and glass, with a filter glyph in the accent where that pill has
its dot. `[→ P3]`

| Rule | |
|---|---|
| One dimension on: **<Dimension> · <values>** — "Category · Kopi, Makan", "Person · Fadil, Tarisa" | `[→ P3, P7]` |
| Several on: the dimensions' values, joined by " · " in §4.1's order — "Makan · BNI" | `[→ P6]` |
| Values follow the sheet row's rule: one or two names, then "+N" | — |
| The whole pill is one button that clears **this filter only** (the plan filter stays) | `[→ P3]` |
| With the plan filter on too, both pills show, **this one above** the plan pill; each clears its own | `[→ P4]` |
| Not drawn in the Plan lens, during Search, or with no filter | `[→ P10]` |

Accessibility: a button labelled "Clear filter" whose value is the pill's text, as
PlanFilterPill.

Options A (a chip per dimension under the toggle) and C (the button only) were drawn and
not chosen `[→ P3·A, P3·C]`.

### 4.5 The SPENDING hero and the split

While a filter is on, the header's **SPENDING** figure on the Expenses tab, and Insights'
**SPENDING** card, show the **filtered total**, with **of Rp <unfiltered total>** under it
in 13pt semibold secondary text. `[→ P3, P7]`

| Rule | |
|---|---|
| The hero is the filtered set's total, after this filter and **before** the plan filter (the plan filter still never moves the hero, `plan-filter.md` decision 5) | `[→ P3, P4]` |
| "of Rp …" is the window's whole total, no filter of any kind | `[→ P3]` |
| The split bar and the Outside / From plan chips describe the **filtered set** | `[→ P3]` |
| The split's show/hide rule (`plan-filter.md` §1.1) runs on the filtered set: with no From-plan spending among it and no plan filter on, no bar and no chips | `[→ P6]` |
| No filter: the header is exactly as today, with no "of" line | `[→ P1]` |

### 4.6 Empty

| Case | What shows | Frame |
|---|---|---|
| List or Month, nothing in the cycle matches | the header (hero Rp 0, "of Rp …", no split), then the InlineMessageCard **Nothing matches these filters** · "No expenses in 31/07/2026 ~ 30/08/2026 match these filters." with a glass **Clear Filters** button (accent label) that empties this filter only | `P6` |
| The filter matches but the plan filter's half is empty | `plan-filter.md` §4.4's message, as today | — |
| Month, a selected day with no match | `plan-filter.md` §4.4's day message with this title: **Nothing matches on Sun, 2 August** / **… today** | — |
| Insights, nothing in the window matches | each chart's ghost bars with **Nothing matches these filters in this period.** | — unit test |

The plan filter's empty messages win when both filters are on and the plan half is what
empties the list.

### 4.8 The plan filter in the sheet

Added on 2026-10-10, after flow P shipped. The sheet's first row is **Plan**, and it edits
the **same plan filter** the split chips set (`plan-filter.md`, `insights-drill-in.md`
§6), on whichever screen the sheet belongs to. `[→ P1, P11]`

| Rule | |
|---|---|
| The row reads **All**, **Outside plan** or **From plan**, the latter two in the accent | `[→ P1]` |
| It pushes a single-choice page: **Outside plan** and **From plan** with their half's dot, then **All** in a card of its own | `[→ P11]` |
| Setting it from the sheet lights the chip and shows PlanFilterPill; tapping a chip or the pill changes the row | — simulator |
| The Filter button's badge counts the plan filter as one more active row | — unit test |
| **Clear All** and the empty card's **Clear Filters** clear the plan filter too; FilterPill still clears this filter only, PlanFilterPill the plan filter only | — simulator |
| The row is offered even when the split is hidden (no From-plan spending); an empty half shows its own message, as `plan-filter.md` decision 7 | — |
| Lifetime is the plan filter's own: it still resets on a page, and on Insights on a chip or cycle change | — |

---

## 5. Expenses tab (List and Month)

| Rule | |
|---|---|
| List shows only matching expenses; a day with none is not drawn; a day header adds up its visible rows | `[→ P3]` |
| Month's cells show the filtered day totals, weighed against the filtered set's heaviest day | `[→ P5]` |
| Month's day list and its default day follow `plan-filter.md` §4.3, run on the filtered set | `[→ P5]` |
| Swipe-to-delete deletes the swiped row | — simulator |
| An edit that moves an expense out of the filter drops it from view; the filter never clears itself | — simulator |

## 6. Insights

| Part | Filtered how |
|---|---|
| **SPENDING card** | §4.5 `[→ P7]` |
| **Spend by Category, Spend by Account** | only matching expenses, ranked and scaled among themselves `[→ P7]` |
| **Spend over Time** | each bar is the matching spend **in that bar's cycle** `[→ P7]` |
| **People leaderboard card** | unchanged `[→ P7]` |

### 6.1 The drill-in

Tapping a breakdown row pushes SpendEntityView carrying the filter, beside the window and
plan filter it already carries. `[→ P8]`

| Rule | |
|---|---|
| The detail has its own Filter button and sheet, seeded from Insights; its changes never flow back | `[→ P9]` |
| The subject's own dimension is **dropped** from the carried filter and **not offered** in the detail's sheet: a Category detail has no Category row, an Account detail no Account row | `[→ P9]` |
| Header total, share, split card, breakdown and list all follow the filter | `[→ P8]` |
| The share reads **X% of what you spent in this window with these filters**, over the filtered window | `[→ P8]` |
| Narrowing (FocusChip) works inside the filtered set | — unit test |
| Uncategorized and Unassigned details drop their dimension too | — unit test |

---

## 7. Plan lens

The Plan lens ignores the filter. In it, the Filter button and the §4.4 pill are not
drawn; returning to List or Month brings them back with the filter unchanged. `[→ P10]`

## 8. Lifetime

All of it is **session view state**, never stored. Expenses and Insights each hold their
own filter, and neither ever sets the other.

### 8.1 Expenses tab

| Event | Filter afterwards |
|---|---|
| App relaunched | All |
| Paging to another cycle (`‹ ›`), and paging back | **All** |
| Payday changed, or the tab reopening on a different cycle | All |
| Switching List ⇄ Month | kept |
| Switching to Plan and back | kept (Plan ignores it) |
| Searching, then clearing the search | kept |
| Switching tabs and back | kept |
| Turning the plan filter on, off or over | kept |

### 8.2 Insights

| Event | Filter (Insights) | Filter (detail) |
|---|---|---|
| App relaunched | All | — |
| Changing the period chip | **kept** | **kept** |
| Picking a cycle in the Pay period menu | **kept** | **kept** |
| Payday changed in Expenses | kept | kept |
| Switching tabs and back | kept | kept |
| Pushing a detail screen | — | carried, minus the subject's dimension |
| Popping back to Insights | Insights' own | — |
| Narrowing or clearing a narrowing | — | kept |
| Turning the plan filter on, off or over | kept | kept |

The plan filter still resets on a chip or cycle change (`insights-drill-in.md` decision
13); this filter does not.

## 9. Unaffected

- **Search** — all-time, its own Category and Period chips; the Expenses filter waits
  behind it.
- **People leaderboard and Person detail** — their own menus, no Filter button.
- **The Plan lens** (§7), and everything the plan shows.
- **The split rule and row tags.**

---

## 10. Decision log

Settled in a grilling session on 2026-10-10. Entries 22–31 are the design calls the owner
approved with flow P the same day.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Four dimensions: **Category, Group, Account, Person** | `P1` |
| 2 | **Several values** per dimension — *owner override*, against a single value per dimension | `P2` |
| 3 | One **Filter** button opening a sheet, rather than a rail of four chips | `P1` |
| 4 | An active filter is marked by a **floating pill** above the tab bar, beside the lit button — *owner override*, against a removable chip per dimension under the toggle (chosen at the design review from three drawn options) | `P3`, `P3·A`, `P3·C` |
| 5 | Several People match **any** of them | `P7` |
| 6 | Group is its **own dimension**, ANDed with Category | — unit test |
| 7 | Every dimension offers its **empty value**: Uncategorized · No group · Unassigned · No one | `P2` |
| 8 | Checklists are **alphabetical**, the empty value last | `P2` |
| 9 | The sheet lists **every entity**, not only those in the window | `P2` |
| 10 | Expenses and Insights each hold **their own** filter | — |
| 11 | Paging to another cycle **resets** the Expenses filter — *owner override*, against keeping it | — |
| 12 | Changing the Insights chip or pay period **keeps** the filter — *owner override*, against resetting it | — |
| 13 | The Plan lens **ignores** the filter; it waits for List / Month | `P10` |
| 14 | **Search is unchanged** | — |
| 15 | SPENDING shows the **filtered total with "of Rp <total>"**; the split describes the filtered set | `P3` |
| 16 | The plan filter and this one **combine by AND** and never reset each other | `P4` |
| 17 | On Insights **everything but the People leaderboard card** follows the filter | `P7` |
| 18 | The drill-in **carries** the filter and can change it; changes do not flow back | `P8`, `P9` |
| 19 | An empty result shows **Nothing matches these filters** with a **Clear Filters** button | `P6` |
| 20 | Checks **apply live**; Done only closes | `P1` |
| 21 | The sheet is **four rows that push checklists** | `P1`, `P2` |
| D1 | AND across dimensions, OR within one | `P6` |
| D2 | Dimension order: Category · Group · Account · Person | `P1` |
| D3 | Relaunch clears; tab switch, lens switch and Search keep | — |
| D4 | A payday change resets the Expenses filter (the cycle moves) and keeps the Insights one | — |
| D5 | Month follows `plan-filter.md` §4.3 on the filtered set | `P5` |
| D6 | Day headers add up visible rows; empty days disappear | `P3` |
| D7 | The drill-in drops and hides the subject's own dimension | `P9` |
| D8 | The filter holds identifiers; a deleted entity drops out quietly | — unit test |
| D9 | The Filter button follows Search's rule: absent with no expenses | — |
| D10 | Words: **Filter**, **Clear All**, **Clear**, **Clear Filters**, **Nothing matches these filters**, **No group**, **No one** | `P1`, `P6` |
| D11 | Its own PRD; `plan-filter.md` §7 and `insights-drill-in.md` §8 point here | — |
| 22 | Filter glyph `line.3.horizontal.decrease`; on: accent glyph and stroke, badge = active dimensions | `P3`, `P6` |
| 23 | Expenses: the button sits beside Monthly Start Date; Insights and detail: trailing | `P3`, `P7`, `P8` |
| 24 | Pill text: "Dimension · values" for one, values joined by " · " for several; a filter glyph instead of the dot | `P3`, `P6`, `P7` |
| 25 | With the plan filter on, the two pills **stack**, this one on top; each clears its own | `P4` |
| 26 | "of Rp …" is 13pt semibold secondary, right under the hero, on Expenses and Insights | `P3`, `P7` |
| 27 | Sheet `.medium`, growing to `.large` for a checklist; Done stays; **Clear <Dimension>** is a text button under the list | `P1`, `P2` |
| 28 | The empty value sits in its own card; Uncategorized wears a dashed circle | `P2` |
| 29 | A help line under the root rows explains OR within a row and AND across rows | `P1` |
| 30 | The empty message's detail is "No expenses in <range> match these filters."; Clear Filters is a glass button | `P6` |
| 31 | A filtered set with nothing from the plan and no plan filter draws no split | `P6` |
| 32 | The sheet gains a **Plan** row bound to the **same** plan filter as the chips — against a separate sheet-only plan filter | `P1`, `P11` |
| 33 | The Plan row is a **single choice** on its own page, not a segmented control on the root | `P11` |
| 34 | The **badge, Clear All and Clear Filters include the plan filter** | `P1` |
| 35 | Plan is the **first** row; its page lists Outside plan, From plan, then All in its own card | `P11` |

---

## 11. Design traceability

Page `02 · Pages · iPhone`, **Flow P · Filter by Category, Group, Account and Person**,
after Flow O. Components `FilterButton`, `FilterPill`, `OfTotalText` and
`InlineMessageCard · Clear` live on `01 · Design System`, group `Filter`; FilterOptionRow
draws as `PickerRow · Category Multi` / `PickerRow · Multi`. The Expenses, Insights and
drill-in toolbars of flows A, C, G, J, N and O now draw the button, off. The marks not chosen
(P3·A, P3·C) are on `05 · Proposals`. One sample, payday 31, "today" Thu 6 August 2026.

| Category | Group |
|---|---|
| Kos, Internet, Makan | Housing & Living |
| Cicilan | Fixed Obligations |
| Kopi | Entertainment & Lifestyle |
| Transport | Transportation & Travel |

| Cycle | Day | Expense | Account | People | Amount | Half |
|---|---|---|---|---|---|---|
| July 2026 | Sun 12 Jul | Makan · Lunch | Cash | — | 60.000 | Outside |
| | Mon 20 Jul | Makan · Dinner | GoPay | Fadil | 55.000 | Outside |
| | Sat 25 Jul | Kopi · Iced latte | GoPay | — | 40.000 | Outside |
| August 2026 (31/07 ~ 30/08) | Fri 31 Jul | Kos | BCA | — | 2.500.000 | From plan (Plan) |
| | Fri 31 Jul | Cicilan · Cicilan Rumah | BNI | — | 1.500.000 | From plan (Plan) |
| | Fri 31 Jul | Internet · IndiHome | BCA | — | 350.000 | From plan (Plan) |
| | Sun 2 Aug | Kopi · Morning coffee | Cash | — | 25.000 | Outside |
| | Sun 2 Aug | Makan · Dinner | GoPay | Fadil | 120.000 | From plan (Hidup) |
| | Wed 5 Aug | Makan · Lunch | Cash | Tarisa | 45.000 | From plan (Hidup) |
| | Thu 6 Aug | Transport · Grab home | GoPay | — | 30.000 | Outside |

August: SPENDING Rp 4.570.000 · Outside plan Rp 55.000 · From plan Rp 4.515.000.

| Filter (August) | Filtered | Outside | From plan |
|---|---|---|---|
| Category = Makan, Kopi | 190.000 | 25.000 | 165.000 |
| Account = GoPay | 150.000 | 30.000 | 120.000 |
| Person = Fadil, Tarisa | 165.000 | 0 | 165.000 |
| Category = Makan · Account = BNI | 0 | 0 | 0 |

| Frame | Covers |
|---|---|
| **P1** · List — the Filter sheet, Category chosen | §4.2 button, §4.3 root rows, Clear All / Done, D2 |
| **P2** · The Category checklist | §4.3 checklist, decisions 7–9, empty value last |
| **P3** · List — Category = Makan, Kopi | §4.2 lit button, §4.4 pill, §4.5 hero + "of", split of the filtered set, §5 rows and day totals |
| **P4** · List — Makan, Kopi + Outside plan | §4.1 AND with the plan filter, hero unmoved by the plan filter, §4.4 stacked pills |
| **P5** · Month — Account = GoPay | §5 cells and weight, default day |
| **P6** · List — Makan + BNI, empty | §4.6 message and Clear Filters, split hidden, D1 |
| **P7** · Insights — Person = Fadil, Tarisa | §6 SPENDING card, charts, trend July 55.000 / August 165.000, leaderboard card unfiltered, decision 5 |
| **P8** · GoPay detail from P7 | §6.1 carried filter, 120.000 = 73% of 165.000 |
| **P9** · The Filter sheet on the GoPay detail | §6.1 no Account row, D7 |
| **P10** · Plan lens with a filter waiting | §7 no button, no pill |
| **P11** · The Plan page of the sheet | §4.8 single choice, All in its own card |
| **P3·A**, **P3·C** · marks not chosen | decision 4 |

### 11.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| A toolbar item cannot carry a custom overlay, and `.badge` on `ToolbarItem` does not exist | `.badge(count)` on the Button inside the item draws iOS's own toolbar badge — **red**, not the accent P3 drew; SwiftUI offers no tint for it | `FilterButton` |
| The two leading toolbar buttons on Expenses | iOS groups Monthly Start Date and Filter into **one glass capsule**; frames redrawn to match | `ExpensesView`, Flow P, A, G, J, N |
| The order of values in a row and the pill | Checklist order (by name), so "Kopi, Makan", never the order ticked; P1, P3 and the pill now read so | `FilterCatalog.summary` |
| VoiceOver read a Person row as "B, Budi" (the avatar's initial) | The row's icon is hidden from accessibility; the row reads its name and the Selected trait | `FilterOptionRow` |
| Which message an emptied Month **day** shows | **Nothing matches on Sun, 2 August / today** · "Clear the filters to show every expense." with Clear Filters, unless the plan filter's half is what emptied it | `EmptyNotice.day` |
| A drill-in that a filter empties | Its title is **Nothing matches these filters** and the message ends "… that match these filters." (the plan filter's title wins when both are on) | `SpendEntityDetail.emptyTitle/emptyMessage` |
| A deleted entity in the filter (D8) | Every render prunes the filter against the catalog built from the live store, so the stored choice simply stops counting | `FilterCatalog.pruning` |
| The derivation | Pure and tested on this PRD's own sample, one test per rule | `ExpenseFilter`, `FilterDimension`, `FilterCatalog`, `EmptyNotice`, `ExpenseFilterTests` (26 tests) |
| The checklist was pushed while the sheet grew from .medium to .large, so it laid out at the small height and left a blank band for a moment (found on the owner's iPhone) | The sheet grows first and the page is pushed 0.35 s later; the root rows became Buttons with their own chevron | `FilterSheet.open` |
| Those Buttons read "Category, All, Category" to VoiceOver | Each row is one element: label the row's title, value its summary | `FilterSheet.row` |
| Simulator | Every row of §8's tables, the empty states, swipe-to-delete, Search and the Plan lens were driven on an iPhone 17 Pro; the badge and VoiceOver bugs above were found there | — |
