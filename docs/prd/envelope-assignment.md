# PRD — Assigning an expense to an Envelope

Status: Accepted — amendment (flow R) in build
Date: 2026-10-13 · flow Q built the same day; flow R (§4.5, §4.6, §4.8, §4.9) approved 2026-10-13
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Envelope this changes, §5.1–5.2),
`docs/prd/plan-filter.md` (the Outside plan / From plan split this feeds), `CONTEXT.md`
(ubiquitous language), `docs/adr/0005-plan-and-ledger-are-separate.md`, and
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
- **Carrying assignments across cycles.** An assignment belongs to one plan (§5.4).

---

## 4. The rule

### 4.1 Where an expense counts

`Expense` gains two fields (schema **V4**, additive):

| Field | Meaning |
|---|---|
| `envelope: PlanItem?` | the Envelope the owner assigned it to; nil = not assigned |
| `isOutsideEnvelopes: Bool` | the owner chose **No envelope** |

At most one of the two is set; the editor and the bulk move write both together. An
expense resolves to **one** of four origins, checked top to bottom:

| # | When | Counts in | Split half | Row tag |
|---|---|---|---|---|
| 1 | `planItem != nil` — a Fixed item created it | its Fixed item | From plan | filled violet **Plan** |
| 2 | `envelope` is set **and** belongs to the plan of the expense's own cycle | that envelope only | From plan | outlined violet, the envelope's name |
| 3 | `isOutsideEnvelopes` | nothing | Outside plan | none |
| 4 | otherwise — **by category** | the active envelope claiming its Category, if any | From plan if claimed, else Outside plan | the claiming envelope's name, or none |

`[→ Q4]`

- Row 2 **wins over row 4**: an assigned `Makan` counts in Travelling and is skipped by
  Hidup, though Hidup claims `Makan`. `[→ Q4, Q5]`
- Row 2 does **not** care whether the envelope claims the expense's Category. That is the
  point.
- An assignment whose envelope belongs to **another cycle's plan** is ignored and the
  expense falls to row 3/4. The editor prevents it (§4.4); this guard covers what the
  editor cannot see — a payday change that re-cuts cycles, a sync from an older build.
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
| the cycle containing the editor's **date** has a plan with ≥ 1 **active** Envelope | no plan, or no active Envelope, for that cycle |
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

**Changing the date** across a cycle boundary resets an assignment to **By category**,
visibly, before Save. **No envelope** survives a date change: it names no plan.
Changing the **Category** never touches the choice. — simulator + unit test

### 4.5 ＋ on an Envelope row

Each active Envelope row in the Plan lens gains a **＋** button trailing its bar and
legend, outside the row's tappable body (so the row still opens the item editor and
VoiceOver reads the two separately). It is a small circle in the plan's violet wash with a
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
| in the future | its first day, at the current time of day |

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
| **Move to envelope…** | the row is selectable and the plan of its **own** cycle has an active envelope | the §4.6 sheet for this one expense, titled **"Move 1 expense"** |
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

### 4.7 Deleting an Envelope

Deletes nullify (ADR-0001): the envelope's assigned expenses fall back to **by category**.
The confirmation says so when there are any:

> "Delete this plan item?" — "3 expenses assigned to it stay in your ledger and go back
> to counting by category."

With none, the body is today's. — unit test

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

- **Carry-over** copies Envelopes, not assignments. Next cycle's Travelling starts empty.
- An Envelope with assigned spending is **in use**, so it is never folded as dormant even
  at Rp 0 planned.
- Editing an Envelope's Categories never touches its assigned expenses.

## 6. Unaffected

- **Fixed items** — Done, Funded, Auto, the drift figure and the transfer checklist.
- **Totals and Sisa** — an Envelope's planned amount is what Total cost reads, as today.
- **Insights** charts by Category, Group, Account and Person: the Category stays true.
- **Search, Month and Person detail** — they show the tags (§5.3) and nothing more.
- **The expense filter** — no new dimension.

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
