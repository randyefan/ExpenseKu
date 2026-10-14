# PRD — Assigning an expense to an Envelope

Status: Built (flows Q, R, S, U)
Date: 2026-10-13 · flow Q built the same day; flow R (§4.5, §4.6, §4.8, §4.9) approved and built the same day;
flow S (§4.10) grilled, approved and built 2026-10-14; flow U (§4.10.10) grilled, approved and built 2026-10-14
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Envelope this changes, §5.1–5.2),
`docs/prd/plan-filter.md` (the Outside plan / From plan split this feeds), `CONTEXT.md`
(ubiquitous language), `docs/adr/0005-plan-and-ledger-are-separate.md`, `docs/adr/0009-assignment-may-pay-ahead.md` (flow S), and
**`design/ExpenseKu.pen`**, page `02 · Pages · iPhone`, **Flow Q** (moved there from
`05 · Proposals` once built). Frame
references appear inline as `[→ Q2]`.

---

## 1. What this is

An Envelope counts an expense by its **Category** alone (`payday-planning.md` §5.2): every
`Makan` expense in the cycle lands in "Hidup (Makan, bensin, emoney saldo)". That breaks
the moment the owner plans an allowance that is about an *occasion* rather than a kind of
purchase. A "Travelling" envelope wants the meals, fuel and hotel of one trip — and the
same `Makan` at home must keep landing in Hidup. A Category cannot tell the two apart, and
§5.2 forbids one Category in two envelopes anyway.

This feature lets the owner **assign** an expense to an Envelope by hand. An assigned
expense counts in that envelope and nowhere else; every other expense keeps counting by
Category exactly as today. The owner can also mark an expense **No envelope**, taking it
out of the plan altogether.

Assignment is reached three ways: a row in the expense editor, a **＋** on an Envelope row
in the Plan lens, and a **Select** mode in the List lens that moves many expenses at once.

## 2. Goals

1. Let an Envelope collect expenses its Categories cannot describe — a trip, an event.
2. Keep the Category on the expense true: a meal on a trip is still `Makan` in Insights.
3. Never count one rupiah twice. An expense lands in at most one envelope (ADR-0005).
4. Make tagging a trip's worth of expenses cheap: add straight into the envelope, or tidy
   up afterwards in one move.

## 3. Non-goals

- **Assigning by date range.** A trip is not modelled; the owner assigns expenses.
- **Remembering the last envelope** for the next expense — *owner override* (§8, #9).
- **An "Envelope" dimension in the expense filter** (`expense-filter.md`), or envelope
  chips in Search.
- **Select mode outside the List lens** — not Month, not Search, not Person detail.
- **Bulk actions other than Move to envelope** (no bulk delete, no bulk recategorise).
- **Assigning an expense a Fixed item created.** It is already From plan; §5.2's exclusion
  is unchanged.
- **Carrying assignments across cycles.** Carry-over never copies one (§5.4). An
  assignment may point *forward* to a later cycle's plan (§4.10), never backward.
- **Creating a plan to pay ahead into.** Only plans that already exist are offered; a
  later cycle's plan is still made only by paging the Plan lens forward (§4.10).

---

## 4. The rule

### 4.1 Where an expense counts

`Expense` gains two fields (schema **V4**, additive):

| Field | Meaning |
|---|---|
| `envelope: PlanItem?` | the Envelope the owner assigned it to; nil = not assigned |
| `isOutsideEnvelopes: Bool` | the owner chose **No envelope** |

At most one of the two is set; the editor and the bulk move write both together. An
expense resolves to **one** of five origins, checked top to bottom:

| # | When | Counts in | Split half | Row tag |
|---|---|---|---|---|
| 1 | `planItem != nil` — a Fixed item created it | its Fixed item | From plan | filled violet **Plan** |
| 2 | `envelope` is set **and** belongs to the plan of the expense's own cycle | that envelope only | From plan | outlined violet, the envelope's name |
| 3 | `envelope` is set **and** belongs to the plan of a **later** cycle — **paid early** (§4.10) | that envelope, in *its* cycle; nothing in the expense's own | Outside plan | dashed violet, **‹name› · ‹Mon›** |
| 4 | `isOutsideEnvelopes` | nothing | Outside plan | none |
| 5 | otherwise — **by category** | the active envelope claiming its Category, if any | From plan if claimed, else Outside plan | the claiming envelope's name, or none |

`[→ Q4, S3]`

- Row 2 **wins over row 4**: an assigned `Makan` counts in Travelling and is skipped by
  Hidup, though Hidup claims `Makan`. `[→ Q4, Q5]`
- Row 2 does **not** care whether the envelope claims the expense's Category. That is the
  point.
- Row 3 **wins over row 5** too: a paid-early expense never falls back to the Category
  claim of its own cycle, or it would count twice — once in Hidup now, once in
  Travelling next month. *Amended by flow S.*
- An assignment whose envelope belongs to an **earlier** cycle's plan is ignored and the
  expense falls to row 4/5. The editor never offers one (§4.10); this guard covers what
  the editor cannot see — a payday change that re-cuts cycles, a sync from an older build.
  — unit test
- An assignment to an envelope that is **not active** (dormant) still counts: an envelope
  with assigned spending is in use, so it is never dormant (§5.4). — unit test
- The same rule feeds every reader through one derivation (`PlanOrigins` and
  `EnvelopeSpend`): the envelope bar, the List header split, the plan filter
  (`plan-filter.md`), the row tags, the Insights drill-in split, and the drift strip's
  envelope overspend.

### 4.2 Envelopes may claim no Category

An Envelope's **Categories** become optional. "Travelling" can claim nothing and live on
assigned expenses alone. `[→ Q6]`

| Envelope state | Row's second line |
|---|---|
| has spending (claimed or assigned) | the bar, as today |
| no spending, claims Categories | the Category names, as today |
| no spending, claims none | **"Assigned expenses only"** |

The editor's Categories row reads **None** in secondary text instead of a red
**Required**. The one-Category-per-envelope-per-plan rule (§5.2) is unchanged.

### 4.3 The editor's Envelope row

The expense editor gains an **Envelope** row directly under **Category**. `[→ Q1, Q3]`

| Shown when | Hidden when |
|---|---|
| the cycle containing the editor's **date** has a plan with ≥ 1 **active** Envelope — *or a later cycle on offer does (§4.10.2, flow S)* | no plan, or no active Envelope, for that cycle or any later one on offer |
| | the expense was created by a Fixed item (`planItem != nil`) |

The row's value:

| Choice | Reads | Style |
|---|---|---|
| by category, an envelope claims the Category | **‹Envelope name› · by category** | secondary |
| by category, none claims it (or no Category yet) | **None** | secondary |
| assigned | **‹Envelope name›** | primary |
| No envelope | **No envelope** | primary |

A long envelope name truncates in the middle of the row, never the "· by category"
suffix. The word **Auto** is not used anywhere in this feature: it already means an
autodebit item.

### 4.4 The picker

Tapping the row pushes **Envelope**, a single-choice list. `[→ Q2]`

```
(tag)   By category                                    ✓
        Makan counts in Hidup (Makan, bensin, emoney saldo)
(⦸)     No envelope
        Outside plan
ENVELOPES
(tray)  Travelling
        Rp 1.315.000 left
(tray)  Hidup (Makan, bensin, emoney saldo)
        Rp 226.900 left
(tray)  Kebutuhan Kos di Jkt (Tisu, sabun, galon)
        Rp 48.300 over
```

Every row is two lines: the name, and a caption-size detail under it. Names wrap rather
than truncate.

- **By category** first, in its own section, led by a grey `tag` glyph. Its detail says
  where the Category would land — **"‹Category› counts in ‹Envelope›"** — or **"Outside
  plan"**, or **"Choose a category first"** with none. **No envelope** second, grey
  `nosign`, detail **"Outside plan"**.
- Then, under a **ENVELOPES** section header, every **active** Envelope of that cycle's
  plan, by **planned amount ↓, name** (the Plan lens's default order), led by a violet
  `tray` glyph, its detail the remainder from `EnvelopeProgress`: "Rp X left" in
  secondary, "Rp X over" in the overspend red.
- The checkmark (accent) marks the current choice.
- Picking a row pops back to the editor. Nothing is saved until **Save**.
- The remainder is the envelope's **saved** state; it does not preview the expense
  being edited.

**Changing the date** past the assigned envelope's cycle resets the assignment to **By
category**, visibly, before Save; a date in that cycle or any earlier one keeps it
(*amended by flow S*, §4.10.4). **No envelope** survives a date change: it names no plan.
Changing the **Category** never touches the choice. — simulator + unit test

*Amended by flow S:* later cycles' envelopes follow the **ENVELOPES** section, one section
per cycle (§4.10.2).

### 4.5 ＋ on an Envelope row

Each active Envelope row in the Plan lens gains a **＋** button trailing its bar and
legend, outside the row's tappable body (so the row still opens the item editor and
VoiceOver reads the two separately). *Amended by `envelope-detail.md` §4.1:* the row's body now
opens the envelope's detail; the item editor is behind its **Edit**. It is a small circle in the plan's violet wash with a
violet plus — not the accent ＋ of the toolbar, which logs an ordinary expense. Its label is
**"Add to ‹name›"**. The bar shortens to make room. `[→ Q5]`

*Amended by flow R:* the ＋ is a **menu** with two items `[→ R3]`:

| Item | Detail line | Does |
|---|---|---|
| **New expense** | "Logged straight into ‹name›" | what ＋ did before — below |
| **Move expenses here…** | "Pick from this cycle's expenses" | opens §4.9 |

**New expense** opens the ordinary **Add Expense** editor with the Envelope row set to that
envelope and the date set to:

| The viewed cycle is… | Date |
|---|---|
| the current one | now |
| in the past | its last day, at the current time of day |
| in the future | **now** — paid early (§4.10.7); *was* its first day before flow S |

so the assignment never resets on open. The ＋ is not drawn on dormant rows or on Fixed
rows. The toolbar's ＋ is unchanged and opens the editor at **By category**.

### 4.6 Select mode — moving many at once

*Amended by flow R:* there is **no Select button**; the toolbar is ＋ and search as before
flow Q. Select mode is entered from a row's long-press menu (§4.8), in the **List lens
only**, and opens with that row already checked. `[→ R1, Q7]`

| | Normal | Select mode |
|---|---|---|
| Leading toolbar | Monthly Start Date + Filter | **Select All** / **Deselect All** |
| Trailing toolbar | ＋ · 🔍 | **Done** |
| Rows | tap opens the editor | tap toggles a leading check circle (accent, filled with a tick when on) |
| Rows a Fixed item created | as today | dimmed to 40%, no circle (its space kept so rows align), not selectable |
| Bottom bar | tab bar | the tab bar is hidden; a glass bar reads **"N selected"** and carries a violet **Move to envelope…** button (disabled at 0) |

- **Select All** selects every *visible*, selectable row — after the plan filter and the
  expense filter — and turns into **Deselect All** once all of them are selected.
- **Move to envelope…** presents the §4.4 picker as a sheet titled **"Move N expenses"**,
  tall enough to show every choice, with a ✕ to close and no Done. It has no checkmark
  (the selection may be mixed), and By category's detail reads **"Each keeps whatever
  its Category says"**. `[→ Q8]`
- Picking a choice applies it to every selected expense at once, saves, dismisses the
  sheet and **leaves select mode**. No confirmation: the move is undone by moving again.
- The plan filter legend, header and day headers behave as today while selecting.

### 4.8 Long-press a row *(flow R)*

Every expense row — List, Month's day list, Search, Person detail and the Insights
drill-in — has an iOS context menu. `[→ R1]`

| Item | Shown when | Does |
|---|---|---|
| **Select** | List lens only, the row is selectable, not already selecting | enters Select mode with this row checked |
| **Move to envelope…** | the row is selectable and the plan of its **own** cycle, or of a later cycle on offer (§4.10.2), has an active envelope | the §4.6 sheet for this one expense, titled **"Move 1 expense"** |
| **Edit** | always | opens the editor, as a tap does |
| **Delete** | always | deletes at once, as swipe-to-delete does |

A row a Fixed item created gets Edit and Delete only. While selecting, rows have no menu.

### 4.9 Move expenses here… *(flow R)*

A `.large` sheet titled **"Move to ‹name›"**, subtitled **"‹cycle title› · ‹remainder›"**,
closed with ✕. `[→ R4]`

- It lists every expense of the **envelope's own cycle** that does not count in this
  envelope now — by category elsewhere, Outside plan, No envelope, or assigned to another
  envelope — each with its tag, newest day first, grouped by day. Rows a Fixed item
  created are not listed.
- Tapping a row toggles its check circle. A violet **"Move N expenses"** button pinned at
  the foot (disabled at 0) assigns them all to this envelope at once, saves and closes.
- Nothing to list: **"Everything this cycle is already in ‹name›."**
- *Amended by flow S:* expenses of earlier cycles may be gathered too (§4.10.8).

### 4.7 Deleting an Envelope

Deletes nullify (ADR-0001): the envelope's assigned expenses fall back to **by category**.
The confirmation says so when there are any:

> "Delete this plan item?" — "3 expenses assigned to it stay in your ledger and go back
> to counting by category."

With none, the body is today's. — unit test

### 4.10 Paying ahead *(flow S)*

The owner's payday is the 25th. Next cycle's plan (November 2026, 25 Oct – 24 Nov) holds
**Travelling** for a trip on the 27th. On 14 Oct the owner buys the train ticket. Its date
puts it in **October**, whose plan has no Travelling, so under rows 2 and 5 the ticket
could only land by Category — in October's Hidup at worst.

An expense may be **assigned to an envelope of a later cycle's plan**. It is then **paid
early**: it keeps its own date, so it stays in its own cycle's ledger, and it counts in
that later envelope and in no envelope of its own cycle. It is counted exactly once
(ADR-0005), and deleting the envelope nullifies the assignment (ADR-0001), returning the
expense to by-category in its own cycle. No schema change: `Expense.envelope` (V4)
already holds it, and the envelope's cycle is `envelope.plan.cycleStart`.

#### 4.10.1 Where a paid-early expense shows

| | Its own cycle (October) | The envelope's cycle (November) |
|---|---|---|
| Ledger: List, Month, Search, cycle total, Insights | listed, by its date | not listed |
| List header split, plan filter, Insights drill-in | **Outside plan** | — |
| Envelope bars and remainders | in none | in **Travelling** |
| Drift strip's envelope overspend | — | counts |
| Row tag | dashed **Travelling · Nov** `[→ S3]` | — |
| Plan lens envelope row | — | caption **"Rp 1.200.000 paid early in October"** `[→ S4]` |

November's List lens never lists the ticket, so its From plan figure can sit below what
Travelling's bar says was spent. That gap is the caption.

#### 4.10.2 Which envelopes are offered

The editor's picker `[→ S1]`, the long-press and bulk **Move N expenses** sheet, the
editor row's visibility (§4.3) and the long-press item (§4.8) all read one list:

1. By category, No envelope — as §4.4.
2. **ENVELOPES** — the active envelopes of the expense's own cycle, as §4.4. Omitted when
   that cycle has none.
3. Then one section per **later** cycle that has a plan **and has not ended** (its end is
   after now), oldest first, headed **"‹CYCLE TITLE› · PAID EARLY"** — "NOVEMBER 2026 ·
   PAID EARLY". It lists that plan's **active** envelopes by planned amount ↓, name, each
   with its remainder (which includes every paid-early expense already in it).

- Every later cycle is offered, not only the next one — *owner override*.
- A plan is **never created** to have something to offer. A cycle with no plan has no
  section; the owner makes one by paging the Plan lens forward (`PlanCarryOver`).
- A cycle that has ended is not offered, however old the expense: a July expense is
  offered July's envelopes and those of the current and future cycles, not August's.
- The **current choice is always drawn**: an assignment to a cycle no longer on offer
  keeps its section so the checkmark shows.
- The editor row and **Move to envelope…** show when any section 2 or 3 has an envelope.

#### 4.10.3 The editor's Envelope row

Assigned to a later cycle's envelope, the row reads **‹name›** in primary text followed
by **"· ‹Mon›"** in secondary — "Travelling · Nov" — and the name truncates, never the
suffix, as with "· by category". `[→ S2]`

#### 4.10.4 Changing the date

| New date's cycle, against the envelope's cycle | The assignment |
|---|---|
| earlier | kept — now paid early |
| the same | kept — now an ordinary assignment (row 2) |
| later | reset to **By category**, visibly, before Save |

This replaces §4.4's "any cycle change resets", for own-cycle assignments too: moving an
October Travelling expense back into September makes it paid early rather than resetting
it. — unit test

#### 4.10.5 The tag

On the expense's own cycle, a paid-early row carries a violet capsule with a **dashed**
outline, an `arrow.forward` glyph and **"‹name› · ‹Mon›"**, where ‹Mon› is the
three-letter month of the envelope cycle's title (the title is its last day's month, so
25 Oct – 24 Nov is "Nov"). A cycle 12 or more cycles ahead adds the year: "Nov 2027". The
name truncates, never the suffix. VoiceOver reads **"Paid early, ‹name›, ‹Month›"**.
`[→ S3]`

The dash is drawn with `StrokeStyle(dash:)` on the capsule; the glyph is `arrow.forward`.
The dashed outline sets it apart from an ordinary envelope tag, which is From plan; this
row is Outside plan.

#### 4.10.6 The envelope row's caption

In the envelope's own cycle, an envelope holding paid-early expenses adds a caption line
under its bar, in secondary text: `[→ S4]`

| Paid-early expenses come from | Caption |
|---|---|
| one earlier cycle | **"Rp 1.200.000 paid early in October"** — that cycle's title month, wide |
| several earlier cycles | **"Rp 1.500.000 paid early"** |
| none | no caption |

It is a third line under the bar's legend, as wide as the bar, caption size, regular
weight; the ＋ stays level with the bar. It is part of the row's body: a tap opens the item
editor, as anywhere on the row. *Amended by `envelope-detail.md` §4.1:* a tap opens the
envelope's detail, which lists the paid-early expenses under "Paid early · ‹cycle›".

#### 4.10.7 ＋ New expense on a future envelope

When the viewed cycle is in the future, ＋ › **New expense** dates the expense **now**,
so it is logged paid early (§4.5 amended). Current and past cycles are unchanged.

#### 4.10.8 Move expenses here…

For an envelope of cycle V, §4.9's sheet lists V's own expenses as before, then — for each
cycle C from **today's cycle** up to the one before V, newest first — that cycle's
selectable expenses not already counting in this envelope, under **"PAID EARLY ·
‹CYCLE TITLE›"**, grouped by day. Ended cycles are not offered. A section with nothing to
list is not drawn; with nothing anywhere the empty text is §4.9's. The subtitle's
remainder includes paid-early expenses. `[→ S5]`

The envelope's own cycle keeps §4.9's look and has **no** section header; only the earlier
cycles are headed. Their header sits above that cycle's day groups.

#### 4.10.9 Deleting and carrying over

- Deleting the envelope nullifies its paid-early assignments with the rest; §4.7's count
  includes them, and they count by Category again in their own cycle.
- Carry-over copies the envelope, never its assignments (§5.4).

#### 4.10.10 Paid early moves money between plans *(flow U)*

Flow S counted the ticket in Travelling's bar but left both plans' **Sisa** alone, so the
money was set aside twice: October's Sisa still offered the Rp 1.200.000 as free, and
November still asked its payday for the whole Rp 2.000.000. The owner's reading: the ticket
was paid with October's money, so November only has to find the rest.

A paid-early expense now **moves its amount from the plan of its own cycle to the plan of
its envelope's cycle**. Total cost keeps its meaning — Σ of the active items' planned
amounts — and each side gains one reconciling row on the totals card, directly under Total cost
and above the Sisa divider: a violet `arrow.forward` glyph, then the label and amount
styled exactly as Total cost (subhead, secondary, amount bold), with a **−** on the own
cycle and a **+** on the envelope's cycle — no green or red. `[→ U1, U2]`

| | Its own cycle (October) | The envelope's cycle (November) |
|---|---|---|
| Row | **"Paid early for November"**, negative | **"Paid early in October"**, positive |
| Amount | Σ of this cycle's paid-early expenses, in full | Σ over envelopes of **min(paid early into it, its planned amount)** |
| Sisa | `income − cost − paid early out` | `income − cost + paid early in` |
| Shown when | the amount is above 0 | the amount is above 0 |

`Sisa = Total income − Total cost − paid early out + paid early in`. The cycle header's
**SISA** headline and the **Over income** strip read the same Sisa: a plan pushed below
zero by paying ahead shows the strip, as any other.

- **The credit is capped at the envelope.** Rp 2.500.000 paid early into a Rp 2.000.000
  Travelling credits November Rp 2.000.000; November never gains more than it planned.
  October is still debited the full Rp 2.500.000 — it is what left October.
- **Drift is unchanged** — *owner override*: November's **Over plan so far** counts
  Travelling's whole overspend, paid-early part included (Rp 800.000 for 2,5jt early plus
  300rb in November), as flow S did. The rupiah over the cap is then reported in both
  October's Sisa and November's drift; the owner prefers the bar and the strip to agree.
- **Transfers are net.** An envelope's contribution to its Account's transfer line is its
  planned amount less the capped credit: Travelling on BCA adds Rp 800.000 to **ke BCA**,
  not Rp 2.000.000. The transfer row's second line says why, in the adjustment line's
  place: **"Rp 1.200.000 paid early into Travelling"**; several envelopes on one account
  read **"Rp X paid early"**. With a manual adjustment too, both share the line, adjustment
  first, joined by " · ". `[→ U3]`
- **Group shares are net** the same way, so the bars add up to Total cost less the credit.
- The envelope row itself is unchanged: planned Rp 2.000.000, its bar
  "Rp 800.000 left", its caption "Rp 1.200.000 paid early in October" (§4.10.6).
- **Labels.** The month is the other cycle's title month, wide, as in the caption:

  | Side | One other cycle | Several |
  |---|---|---|
  | own cycle | **Paid early for November** | **Paid early for later cycles** |
  | envelope's cycle | **Paid early in October** | **Paid early** |

- A cycle with **no plan** shows no totals card, so the debit appears nowhere; the
  envelope's cycle still takes its credit.
- Deleting the envelope, or reassigning the expense, removes both rows at once — they are
  derived per read through `EnvelopeClaims`, never stored.
- The row is not tappable; the envelope's detail (`envelope-detail.md`) lists the
  expenses.

---

## 5. Lifetime

### 5.1 Select mode

Select mode is view state of the List lens, never stored.

| Event | Select mode afterwards |
|---|---|
| Done | off, selection cleared |
| Move applied | off, selection cleared |
| Paging to another cycle (`‹ ›` or swipe) | off, selection cleared — cleared in `ExpensesView.page(to:edge:)` |
| Switching lens (Month, Plan) | off |
| Switching tab | off |
| Toggling the plan filter or the expense filter | **kept**; rows that left the list leave the selection |
| App relaunched | off |

### 5.2 The editor's choice

The choice is part of the editor's draft: it counts as a change for the discard guard
and is written only on Save.

### 5.3 Rows and tags

A tagged row looks exactly like an envelope row today: the outlined violet tag carries the
envelope's name whether the expense was assigned or claimed by Category. A **No envelope**
row carries no tag, like any Outside-plan row. `[→ Q4]`

### 5.4 Across cycles

- **Carry-over** copies Envelopes, not assignments. Next cycle's Travelling starts empty
  of this cycle's assignments; expenses paid early into it are already its own (§4.10).
- An Envelope with assigned spending is **in use**, so it is never folded as dormant even
  at Rp 0 planned.
- Editing an Envelope's Categories never touches its assigned expenses.

## 6. Unaffected

- **Fixed items** — Done, Funded, Auto, the drift figure and the transfer checklist.
- **Totals and Sisa** — an Envelope's planned amount is what Total cost reads, as today.
  *Amended by flow U:* paying ahead adds a reconciling row on each side (§4.10.10);
  Total cost itself is unchanged.
- **Insights** charts by Category, Group, Account and Person: the Category stays true.
- **Search, Month and Person detail** — they show the tags (§5.3) and nothing more.
- **The expense filter** — no new dimension.
- *Flow U:* the envelope row, drift, the Funded notice (Fixed items only), the List
  lens's split and the cycle total.
- *Flow S:* the schema (no V5), the cycle total, Insights by Category, and the List lens of
  the envelope's cycle, which never lists an expense dated before it.

---

## 7. Sample data

One cycle, the `-seedPlanData normal` plan plus:

| Envelope | Planned | Categories |
|---|---|---|
| Hidup (Makan, bensin, emoney saldo) | Rp 938.300 | Makan, Bensin, E-money |
| Kebutuhan Kos di Jkt (Tisu, sabun, galon) | Rp 193.900 | Tisu, Sabun, Galon |
| **Travelling** | **Rp 2.000.000** | — none |

| Expense | Category | Choice | Lands in |
|---|---|---|---|
| (seed) | Makan Rp 420.000 · Bensin Rp 191.400 · E-money Rp 100.000 | by category | Hidup — Rp 711.400 → **Rp 226.900 left**, unchanged |
| Nasi Padang Bandung | Makan Rp 85.000 | Travelling | Travelling |
| Bensin ke Bandung | Bensin Rp 150.000 | Travelling | Travelling |
| Hotel Bandung | Sewa Rp 450.000 | Travelling | Travelling |
| Kado ultah Tarisa | Makan Rp 250.000 | No envelope | nothing — Outside plan |

Travelling: Rp 685.000 of Rp 2.000.000 → **Rp 1.315.000 left**. Hidup is not moved by
the two Travelling `Makan`/`Bensin` rows nor by the gift.

### 7.1 Paying ahead *(flow S, `-seedPlanData paid-early`)*

Today 14 Oct 2026, payday 25. The `-seedPlanData normal` plan for **October 2026**
(25 Sep – 24 Oct), unchanged, with no Travelling. **November 2026** (25 Oct – 24 Nov) has a
plan carried over from October, plus:

| Envelope (November) | Planned | Categories |
|---|---|---|
| Travelling | Rp 2.000.000 | — none |
| Hidup (Makan, bensin, emoney saldo) | Rp 938.300 | Makan, Bensin, E-money (carried over) |
| Kebutuhan Kos di Jkt (Tisu, sabun, galon) | Rp 193.900 | Tisu, Sabun, Galon (carried over) |

| Expense | Date | Category | Choice | October | November |
|---|---|---|---|---|---|
| Tiket KAI ke Jakarta | 14 Oct | Transport Rp 1.200.000 | Travelling (Nov) | listed, **Outside plan**, tag **Travelling · Nov**; in no envelope | Travelling: Rp 1.200.000 of Rp 2.000.000 → **Rp 800.000 left**, caption **"Rp 1.200.000 paid early in October"** |
| (seed) | — | Makan, Bensin, E-money | by category | Hidup **Rp 226.900 left**, unchanged | — |

October's split gains Rp 1.200.000 Outside plan. November's List lens is empty of it.
Gathering into November's Travelling on 14 Oct, before the ticket is assigned, lists no
November expenses and, under **PAID EARLY · OCTOBER 2026**, October's selectable expenses
— the ticket among them, untagged. `[→ S5]`

With flow U, take October's income as Rp 10.000.000 and Travelling on account BCA:

| | October | November |
|---|---|---|
| Totals card | **Paid early for November −Rp 1.200.000**; Sisa Rp 1.200.000 lower | **Paid early in October +Rp 1.200.000**; Sisa Rp 1.200.000 higher |
| Transfers | — | **ke BCA** counts Travelling as Rp 800.000, second line "Rp 1.200.000 paid early into Travelling" |
| Travelling row | — | unchanged: Rp 2.000.000, "Rp 800.000 left", caption |

Capped case (unit test): Rp 2.500.000 paid early, Rp 300.000 spent in November → October
−Rp 2.500.000, November +Rp 2.000.000, Travelling "Rp 800.000 over", Over plan so far
Rp 800.000, ke BCA counts Travelling as Rp 0.

## 8. Decision log

Settled in a grilling session on 2026-10-13.

| # | Decision | Drawn in |
|---|---|---|
| 1 | An assigned expense counts **only** in its envelope; unassigned ones keep the Category rule | `Q4`, `Q5` |
| 2 | Stored as a new relationship `Expense.envelope` (schema V4), not by reusing `planItem` | — |
| 3 | An Envelope may claim **no** Category | `Q5`, `Q6` |
| 4 | The editor's Envelope row sits under Category and shows only when the date's cycle has an active Envelope; hidden on Fixed-created expenses | `Q1`, `Q3` |
| 5 | Unassigned, the row reads **‹name› · by category**, or **None** | `Q1` |
| 6 | A **No envelope** choice exists — *owner override*, against leaving it out | `Q2` |
| 7 | The picker lists By category, No envelope, then active Envelopes by amount ↓ with their remainder | `Q2` |
| 8 | Moving the date to another cycle resets an assignment to By category | — simulator |
| 9 | Shortcuts are the **＋ on an Envelope row** and **bulk select** — *owner override*, against a sticky last-used envelope | `Q5`, `Q7` |
| 10 | The ＋ is a visible button on the row's bar line | `Q5` |
| 11 | Select mode lives in the **List lens only** | `Q7` |
| 12 | Entered by a **Select** toolbar button; a bottom bar carries "N selected · Move to envelope…" | `Q7` |
| 13 | Paging, lens switch or tab switch leaves select mode | — |
| 14 | **Select All** exists and selects only visible, selectable rows | `Q7` |
| 15 | Tags do not distinguish assigned from by-category | `Q4` |
| 16 | Its own PRD; `payday-planning.md` §5.2 carries an "amended by" note | — |
| A | No envelope survives a date change | — unit test |
| B | Changing the Category never changes the choice | — |
| C | Deleting an Envelope returns its assigned expenses to by category; the confirmation counts them | — unit test |
| D | Assignments never carry over; an Envelope with assigned spending is never dormant | — unit test |
| E | The ＋ dates the new expense now, or the viewed cycle's last/first day | — |
| F | Only active Envelopes are offered, in the picker and the bulk sheet | `Q2`, `Q8` |
| G | Every reader resolves origins through one derivation | — |
| H | A bulk move applies at once, without confirmation, and leaves select mode | `Q8` |
| I | No envelope filter dimension; no select mode in Search or Month | — |
| J | Words: Envelope · By category · No envelope · Select · Select All · Move to envelope… · Move N expenses · Add expense to ‹name› | all |
| K | ADR-0008 records that an assignment overrides the Category claim | — |
| 27 | The Select text button is removed; Select mode is entered by long-pressing a row — *owner override of decision 12*, after living with it | `R1` |
| 28 | Long-press works on every expense list; Select only in the List lens | `R1` |
| 29 | The envelope's ＋ becomes a menu: New expense · Move expenses here… | `R3` |
| 30 | Move expenses here… lists every cycle expense not already counting in the envelope | `R4` |
| L | Move to envelope… on a row only when its own cycle has an active envelope; Fixed rows get Edit and Delete | — |
| M | Delete in the menu behaves as swipe-to-delete | — |
| N | Flow R's B (capsule glyph) and D (swipe right) are not built; they stay on page 05 | — |
| 17 | Picker glyphs: grey `tag` for By category, grey `nosign` for No envelope, violet `tray` per envelope | `Q2` |
| 18 | Picker details (remainder, where by-category lands) sit on a second line, not trailing | `Q2` |
| 19 | The bulk sheet's By category reads "Each keeps whatever its Category says" | `Q8` |
| 20 | The ＋ is a violet-wash circle trailing bar and legend, not the accent ＋ | `Q5` |
| 21 | Select is a glass text button; the order is Select · ＋ · 🔍 | `Q4` |
| 22 | In select mode Select All replaces the leading capsule, Done the trailing buttons, and a selection bar replaces the tab bar; Move is violet | `Q7` |
| 23 | A Fixed row in select mode is at 40% with its circle's space kept | `Q7` |
| 24 | The bulk sheet is tall enough for every choice, closes with ✕, has no Done | `Q8` |
| 25 | An envelope with no Categories and no spending reads "Assigned expenses only" | — not drawn |
| 26 | Long meta lines truncate as today; the frames shorten them only to stay legible | `Q4`, `Q7` |

Settled when the owner approved flow Q on 2026-10-13: entries 17–26.

### 8.1 Flow S — paying ahead

Settled in a grilling session on 2026-10-14; the owner chose option 4 of four (rejected:
changing the expense's date, a manual "No envelope + reduce next month's envelope", and a
Fixed item in the current cycle).

| # | Decision | Drawn in |
|---|---|---|
| 31 | An expense may be assigned to an envelope of a **later** cycle's plan — paid early; never an earlier one | `S1` |
| 32 | Only plans that exist are offered; none is created speculatively | — |
| 33 | It keeps its date: listed, totalled and split in its own cycle, in no envelope there | `S3` |
| 34 | In its own cycle it is **Outside plan** in the split, the plan filter and Insights | `S3` |
| 35 | **Every** later cycle with a plan is offered, not only the next — *owner override*, against next cycle only | `S1` |
| 36 | The picker keeps **ENVELOPES** for the own cycle and adds **"‹CYCLE TITLE› · PAID EARLY"** per later cycle | `S1` |
| 37 | The envelope's cycle counts it in bar, remainder and drift; its row gains **"Rp X paid early in ‹Month›"**; its List lens is unchanged | `S4` |
| 38 | Move expenses here… also offers expenses from today's cycle up to the one before the envelope's, under **PAID EARLY · ‹CYCLE TITLE›** | `S5` |
| 39 | ＋ › New expense on a future cycle's envelope dates it **now** | — |
| 40 | The editor row and Move to envelope… show when the own cycle **or** a later cycle on offer has an active envelope | `S1` |
| 41 | Tag text **"‹name› · ‹Mon›"** | `S3` |
| 42 | Tag style: **dashed** violet outline, `arrow.forward` glyph | `S3` |
| 43 | A date change keeps the assignment while the new cycle is not after the envelope's; otherwise resets to By category | — unit test |
| 44 | Ended cycles are never offered, however old the expense | `S1` |
| O | Paid early beats the own cycle's Category claim, so it is counted once; an assignment backward is ignored | — unit test |
| P | Counting has no time limit; only offering does. A chosen envelope in a cycle no longer offered keeps its section | — unit test |
| Q | Only active envelopes are offered in later cycles too | `S1` |
| R | Editor row: name primary, "· ‹Mon›" secondary, the suffix never truncates | `S2` |
| S | Caption names the month only when every paid-early expense comes from one cycle; it is not tappable apart from the row | `S4` |
| T | The tag adds the year 12 or more cycles ahead | — |
| U | Bulk Move N expenses uses the same sections | — |
| V | Delete-envelope confirmation counts paid-early expenses; carry-over never copies them | — unit test |
| W | No schema change: the envelope's cycle is derived from `envelope.plan.cycleStart` | — |
| X | Amendment here (§4.10) plus **ADR-0009**; CONTEXT.md gains **Paid early**; seed `-seedPlanData paid-early` | — |

Settled when the owner approved flow S on 2026-10-14:

| # | Decision | Drawn in |
|---|---|---|
| 45 | The tag's dash is `StrokeStyle(dash:)`, its glyph `arrow.forward` (lucide `arrow-right` in the .pen, which has no dashed stroke) | `S3` |
| 46 | November's section lists every active envelope of that plan, not only ones without Categories | `S1` |
| 47 | The editor's "· ‹Mon›" suffix is styled as "· by category" | `S2` |
| 48 | The caption is a third line under the legend, caption size, regular weight; ＋ stays level with the bar | `S4` |
| 49 | In Move expenses here…, only earlier cycles are headed; the envelope's own cycle has no header, as before | `S5` |
| 50 | The frames shorten meta lines to stay legible; the app truncates as today (#26) | `S3` |

### 8.2 Flow U — paid early moves money between plans

Raised by the owner on 2026-10-14 after living with flow S on a device: a Rp 500.000
ticket paid early into November's Rp 2.000.000 Travelling left November's Sisa unmoved.
Grilled the same day; no design asked for, then allowed.

| # | Decision | Drawn in |
|---|---|---|
| 51 | Paying ahead lowers what the envelope's cycle must find: its **Sisa** rises by the paid-early amount | `U2` |
| 52 | The own cycle carries it: its **Sisa** falls by the same amount, so the money is set aside once | `U1` |
| 53 | Over the envelope's planned amount, the credit is capped; **Over plan so far** still counts the whole overspend — *owner override*, against counting only the envelope cycle's own overspend | — unit test |
| 54 | Transfer lines and Group shares count the envelope net of its capped credit | `U3` |
| 55 | Each side shows a reconciling row — "Paid early for ‹Month›" / "Paid early in ‹Month›" — and Total cost stays Σ planned | `U1`, `U2` |
| Y | The row shows only above Rp 0; several cycles read "for later cycles" / "Paid early" | — unit test |
| Z | The SISA headline and the Over income strip follow the new Sisa | `U1` |
| AA | The envelope row, its caption, the Funded notice and the List lens are unchanged | — |
| AB | Amendment here (§4.10.10) plus an amendment to **ADR-0009** | — |

Settled when the owner approved flow U on 2026-10-14:

| # | Decision | Drawn in |
|---|---|---|
| 56 | The reconciling row carries a violet `arrow.forward`, as the paid-early tag does; otherwise it is styled as Total cost | `U1`, `U2` |
| 57 | It sits directly under Total cost, above the Sisa divider | `U1`, `U2` |
| 58 | Signs only: **−** own cycle, **+** envelope's cycle, both in secondary | `U1`, `U2` |
| 59 | The transfer row explains the net figure in its second line, sharing it with an adjustment | `U3` |
| 60 | The transfers get their own frame, U3 | `U3` |

## 9. Design traceability

Page `02 · Pages · iPhone`, **Flow Q · Assign an expense to an Envelope**. Components
`EnvelopeFormRow`, `EnvelopeChoiceRow`, `SelectionCircle · On / Off` and `SelectionBar` live
on `01 · Design System`, group `Cycle plan`, row `Envelope assignment`; `PlanEnvelopeRow`
carries the ＋ itself, so every envelope row on page 02 shows it.

| Frame | Covers |
|---|---|
| **Q1** · Editor — by category | §4.3 row placement and the "· by category" value |
| **Q2** · Envelope picker | §4.4 order, remainders, No envelope |
| **Q3** · Editor — assigned to Travelling | §4.3 primary value |
| **Q4** · List lens — tags and split | §4.1 table, §5.3 tags, No envelope untagged |
| **Q5** · Plan lens — Travelling with ＋ | §4.2 no Categories, §4.5 ＋, Hidup unchanged |
| **Q6** · Plan item editor — Envelope without Categories | §4.2 optional Categories |
| **Q7** · List lens — Select mode | §4.6 toolbar, check circles, dimmed Fixed row, bottom bar |
| **Q8** · Move N expenses | §4.6 the sheet |
| **R1** · Long-press a row | §4.8 the menu, §4.6 entry |
| **R3** · ＋ menu on an envelope | §4.5 amended |
| **R4** · Move to Travelling | §4.9 |

Flow R sits on page 02 after flow Q; its options B and D stay on page 05 as not chosen.

**Flow S · Paying ahead into a later cycle's envelope**, on page 02 after flow R (drawn
on 05 first), with the §7.1 sample in every frame. Component `PlanOriginTag · Paid early`
lives on `01 · Design System`, group `Cycle plan`, row `Envelope assignment`; S3 uses it.

| Frame | Covers |
|---|---|
| **S1** · Envelope picker — October expense | §4.10.2 sections, remainders, ENVELOPES kept |
| **S2** · Editor — Travelling · Nov | §4.10.3 the row's value |
| **S3** · List lens, October — the ticket | §4.10.1 Outside plan, §4.10.5 dashed tag |
| **S4** · Plan lens, November — Travelling | §4.10.1 bar, §4.10.6 caption |
| **S5** · Move to Travelling — November | §4.10.8 PAID EARLY section |

**Flow U · Paid early moves money between plans**, on page 02 after flow T (drawn on 05
first), with the
§7.1 sample:

| Frame | Covers |
|---|---|
| **U1** · Plan lens, October — totals card | §4.10.10 the debit row, Sisa, SISA headline |
| **U2** · Plan lens, November — totals card and Travelling | §4.10.10 the credit row, Sisa, the unchanged envelope row |
| **U3** · Payday, November — transfers | §4.10.10 net ke BCA and its second line |

### 9.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| Add Expense opened from ＋ showed "None": an `isPresented` sheet built its content before the preset landed | Add Expense is a `.sheet(item:)` carrying `NewExpensePreset`; the toolbar ＋ passes an empty one | `ExpensesView`, `NewExpensePreset` |
| `LabeledContent` stacked a long envelope value under its label, and VoiceOver read "Envelope" twice | The row is an explicit HStack — label, then name (truncates) and suffix (never) — read as one element, label "Envelope" | `EnvelopeFormRow` |
| Search stayed in the toolbar during Select mode | Search is off while selecting; Q7 draws only Select All and Done | `ExpensesView` |
| §5.1 "switching tab leaves select mode" | The tab bar is hidden while selecting, so a tab switch cannot happen; `onDisappear` still clears it | `ExpensesView` |
| By category's detail with no Category yet | "Choose a category first" | `EnvelopeOptions` |
| An active envelope always draws its bar (Rp 0 spent included), so §4.2's "Assigned expenses only" is only reachable where no progress exists | Kept as the empty text, replacing "No categories yet" | `PlanEnvelopeRow` |
| The rule, the editor's choice and Select mode | Pure and tested against §7's sample | `EnvelopeClaims`, `EnvelopeChoice`, `EnvelopeOptions`, `EnvelopeAddDate`, `ExpenseSelection`; `EnvelopeAssignmentTests`, `EnvelopeChoiceTests` |
| A V3 store opens unchanged | `Fixtures/PlanV3.store`, written by the V3 code before the change | `StoreMigrationTests` |
| Simulator sample | `-seedPlanData travelling` | `DebugPlanSeed` |
| Flow R: Move expenses here… rows showed no envelope tags — the sheet sits outside the `planOrigins` environment | The sheet is handed `planOrigins` explicitly | `ExpensesView` |
| Flow R: in a row narrowed by a check circle, the meta text broke "Cash" mid-word because the tag takes layout priority | A Dynamic-Type-scaled floor on the meta text; the tag truncates instead | `ExpenseMetaLine` |
| Flow R: menu item subtitles did not show when both Texts sat inside a `Label` | A `Label` plus a second `Text` in the Button | `PlanEnvelopeRow` |
| Flow R: `LeaderboardFilters` used `ForEach` over `Account` without importing SwiftData, and only compiled by luck of batch grouping; the new files moved the batches | `import SwiftData` | `LeaderboardFilters` |

### 9.2 Closed during implementation — flow S

| Gap | Answer | Where |
|---|---|---|
| Which envelopes are on offer was worked out in four places (picker, Move sheet, row menu, editor row) | One pure `EnvelopeOffer` (own cycle, then later open cycles, plus the current choice); `EnvelopeOptions` wraps it with remainders | `EnvelopeOffer`, `EnvelopeSection`, `EnvelopeOptions` |
| `EnvelopeClaims` could not tell a later envelope from an earlier one | It now knows its cycle: `paidEarlyTarget(of:)` and `paidEarly(into:)` sit beside `envelope(for:)`, so the resolver stays the one place | `EnvelopeClaims` |
| A cycle's bars were fed only that cycle's dated expenses | `EnvelopeSpend.progress` takes the cycle and adds each envelope's paid-early assignments, keeping them apart for the caption | `EnvelopeSpend`, `EnvelopeProgress` |
| The split and the plan filter treated any origin as From plan | `PlanOrigin.isFromPlan`; `.paidEarly` is tagged yet Outside plan, Insights included | `PlanOrigins`, `PlanFilter` |
| ＋ was pinned to the row's bottom, so the caption would have pulled it down | A custom alignment guide at the bar line; ＋ aligns to it | `EnvelopeBarLine`, `PlanEnvelopeRow` |
| A Move request carried a plan, and a List-lens move from a cycle without one had nothing to offer | The request carries the cycle; the sheet builds the offer from all plans | `EnvelopeMoveRequest`, `EnvelopeMoveSheet` |
| The gather sheet only queried the envelope's cycle | It queries from today's cycle start (`EnvelopeGather.earliestStart`) | `EnvelopeGatherSheet` |
| A long note beside the wider paid-early tag wraps to three lines | Kept: the meta line's existing floor and line limit (#26); the tag never truncates "· Nov" | `ExpenseMetaLine` |
| The rule, the offer, the labels, the caption and gathering | Pure and tested against §7.1 | `PaidEarlyTests` (14) |
| Simulator sample | `-seedPlanData paid-early`; on a simulator whose payday is not 25 the dates shift, the rules do not | `DebugPlanSeed` |

### 9.3 Closed during implementation — flow U

| Gap | Answer | Where |
|---|---|---|
| Where both sides' figures come from | One pure `PaidEarlyShift`: outgoing through `EnvelopeClaims.paidEarlyTarget(of:)`, incoming from each `EnvelopeProgress` capped at its plan, and the per-envelope credit the transfers and shares subtract | `PaidEarlyShift`, `PlanContents` |
| Total cost could have absorbed the shift silently | `PlanTotals` keeps `totalCost` Σ planned and carries the shift beside it; `sisa` applies both | `PlanTotals` |
| A separate "+" Text did not scale with `MoneyText`'s minimum scale factor, so it sat larger than the figure | `MoneyText(showsPlus:)` puts the sign in the same string | `MoneyText`, `PlanTotalsCard` |
| The transfer row's one-line subtitle truncated the envelope's name ("Travelli…"), the part that explains the figure | It wraps to two lines when it carries a paid-early credit; other subtitles stay one line | `TransferRowView` |
| The §7.1 sample put Travelling on no account, so ke BCA could not be observed | `-seedPlanData paid-early` puts Travelling on BCA | `DebugPlanSeed` |
| VoiceOver read the glyph | The arrow is hidden; the row reads "Paid early in October, +Rp 1.200.000" | `PlanTotalsCard` |
| No new view type | The row is a private helper of `PlanTotalsCard`; the DS `PlanTotals` component's notes describe it, and U1/U2 draw it | `.pen` page 01 |
| The rules | Pure and tested against §7.1 | `PaidEarlyShiftTests` (10) |

