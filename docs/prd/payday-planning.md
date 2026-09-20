# PRD — Payday Planning

Status: Accepted
Date: 2026-09-20
Owner: Randy Efan

Companion documents: `CONTEXT.md` (ubiquitous language), `docs/adr/0005`–`0007`
(the three decisions in here that are hard to reverse), `docs/design-brief.md`
(the visual language this must live inside), and **`design/ExpenseKu.pen`** — every
screen this document describes is drawn there. Frame references appear inline as
`[→ E2]` and are indexed in full in §11.

---

## 1. What this is

The owner keeps a **salary-allocation spreadsheet** outside the app. A few days before
payday they open it, list what the next cycle owes, and work out what is left. Nine
cycles of it exist (Jan–Sep 2026): income sources at the top, a cost table in the
middle, and three rollup blocks at the foot.

This feature moves that spreadsheet into ExpenseKu, and connects it to the expenses the
owner already logs day to day — which the spreadsheet cannot do.

The spreadsheet's structure, reverse-engineered and arithmetically verified against all
nine cycles:

| Block | Columns | Formula | Becomes |
|---|---|---|---|
| Income | source, amount, "Sudah Masuk" ☑ | `Total Income = Σ` | `E1` income card |
| Cost table | name, category, priority, amount, Done (☐/☑/Auto), account | `Total Cost = Σ` | `E2` plan items |
| Sisa | — | `Total Income − Total Cost` | `E1` totals + cycle header |
| Transfer footer | "ke BNI", "ke Mandiri", … | `Σ cost GROUP BY account`, plus a manual adjustment on one account | `E3` checklist, `I2` adjustment |
| Category % | 6 coarse categories | `Σ per category ÷ Total Income` | `E3` share table |
| Priority ladder | P0 / P1 / P2 | running remainder per tier | **dropped** (§4) |

## 2. Why it does not already fit

`CONTEXT.md` rules three things out of scope for v1 — **budgets, recurring expenses,
and income tracking** — and defines Account as *"a label only — not a balance-bearing
ledger."* The spreadsheet needs all four ideas in some form. This feature therefore
changes the domain model, not just the UI, and the changes are recorded as ADRs.

The sharpest distinction it introduces: the spreadsheet's *Pengeluaran* column is **not**
an `Expense`. It is a planned allocation — money the owner intends to move. An `Expense`
is money that already left. Conflating them would double-count every cycle total, every
chart, and the People leaderboard.

## 3. Goals

1. Replace the spreadsheet entirely for the payday routine.
2. Keep the daily logging path — the ＋ button — **completely unchanged**. It is used
   many times a day; the plan is touched once a cycle. `[→ F2, where plan items are
   added from the list foot instead]`
3. Never let planned money appear as spent money. `[→ G3 — the plan's expenses are
   ordinary expenses, and Sisa does not move as they land]`
4. Give the owner two things the spreadsheet cannot: envelopes that total themselves
   from real expenses, and plan-vs-actual on every line. `[→ E2 both; G2 drift on a
   posted Auto item]`

## 4. Non-goals for v1

- **Priority tiers (P0/P1/P2)** and the running-remainder ladder. Dropped: P2 was never
  once used across nine cycles, and P1 held the same four subscriptions every month.
- **An importer.** The owner types one cycle by hand; carry-over covers every cycle after.
- **Account balances, transfers between accounts, reconciliation.** Accounts stay labels.
- **Income anywhere outside a plan.** No income tab, no income charts, no net worth.
- **Plan-vs-actual percentages per Group.** The percentage table shows planned only.
- **Account types.** Verified against the data: credit cards are summed exactly like
  every other account (`ke CC Danamon` = Σ of its rows, all nine cycles). No special case.

---

## 5. Domain model

```
CyclePlan  ── exactly one per PayCycle, keyed by the existing Payday anchor
├── IncomeLine[]    name · amount · hasArrived
├── PlanItem[]
│   ├─ Fixed        amount · Category · Account · People · dueDay? · isAuto · isDone
│   │                └─ isDone ──▶ Expense  (1:1 link)
│   └─ Envelope     amount · Category set
│                    └─ spent = Σ Expense in this cycle whose Category is in the set
│                       AND which is not linked to any Fixed PlanItem
└── TransferLine[]  per Account: derived Σ · manual adjustment · hasTransferred

Group               a coarse bucket above Category (Fixed Obligations, Lovely Support,
                    Housing & Living, Entertainment & Lifestyle, Personal Care,
                    Transportation & Travel)
```

Where each part is drawn:

| Model | Drawn in |
|---|---|
| `CyclePlan` | `E1` (top), `E2` (items), `E3` (rollups) |
| `IncomeLine` · name · amount · hasArrived | row `IncomeRow` in `E1`; editor `I1`; ticked in `G1` |
| `PlanItem` · Fixed — all seven fields | row `PlanFixedRow` in `E2`; editor `F1`; `I8` for Auto without a due day |
| `isDone ──▶ Expense` (1:1) | created in `E4`; undone in `I4`; link dropped in `I7` |
| `PlanItem` · Envelope · amount · Category set | row `PlanEnvelopeRow` in `E2`; editor `F3`; Category set `F4` |
| Envelope `spent` | the bar in `E2` (under and over), filling in `G2` |
| `TransferLine` · Σ · adjustment · hasTransferred | `E3`; adjustment editor `I2` |
| `Group` | `H2` list, `H3` editor, `H4` assignment |

Derived, never stored:

```
Total Income   = Σ IncomeLine.amount
Total Cost     = Σ PlanItem.amount          (Fixed and Envelope alike)
Sisa           = Total Income − Total Cost
Transfer line  = Σ PlanItem.amount for that Account + adjustment
Group %        = Σ PlanItem.amount per Group ÷ Total Income
```

All five appear in `PlanTotals` (`E1`) except the transfer line, whose arithmetic is
shown in full in `I2`, and Group %, which is `GroupShareRow` in `E3`.

### 5.1 The two kinds of PlanItem

The spreadsheet mixes them in one table, and the difference is visible in the numbers.
Round, forward-looking amounts are **Fixed**:

```
Kos Rp 2.200.000 · Cicilan Rumah BNI Rp 7.706.000 · Netflix Rp 130.000
```

Precise amounts filled in after the fact are **Envelopes** — dozens of small purchases
totalled by hand at the end of the cycle:

```
Hidup (Makan, bensin, emoney saldo)        Rp 938.300
Kebutuhan Kos di Jkt (Tisu, sabun, galon)  Rp 193.900
Entertainment (Nongkrong, pacar, …)        Rp 187.000
```

An Envelope never produces an Expense. Its `spent` is computed from expenses the owner
already logged — which is the single biggest improvement over the spreadsheet, because
that column stops being manual work and becomes live during the cycle.
`[→ F3 the kind toggle, E2 both rows side by side]`

### 5.2 Why an Envelope scopes to Categories, not to a Group

Five February rows share one Group:

```
Kos                                   Housing & Living   Rp 2.200.000   Fixed
Listrik Kos                           Housing & Living   Rp   200.000   Fixed
Bayar parkir motor SQ                 Housing & Living   Rp   650.000   Fixed
Hidup (Makan, bensin, emoney saldo)   Housing & Living   Rp   938.300   Envelope
Kebutuhan Kos di Jkt                  Housing & Living   Rp   193.900   Envelope
```

A Group-scoped envelope would swallow the other four rows. The envelope names already
spell out their own scope — *"Makan, bensin, emoney saldo"* is a list of Categories.

**Rules:**
- A Category belongs to **at most one Envelope per CyclePlan**. The picker must exclude
  Categories already claimed by another envelope in the same plan. `[→ F4]`
- An Expense linked to a Fixed PlanItem is **excluded from every envelope**, regardless
  of its Category.
- An Expense whose Category is in no envelope is simply unbudgeted. It counts in cycle
  spending as it always has; it counts toward no envelope.

### 5.3 Category and Group

Two vocabularies exist today and they are not synonyms:

- **Category** (existing, fine): `Makan`, `Transport`, `Kopi` — *what* was bought.
  Unchanged. Still the only thing chosen when logging an expense.
- **Group** (new, coarse): the six spreadsheet buckets — *what the money is for*.
  A Category belongs to zero or one Group. Only the percentage table uses it.
  `[→ H4 assignment, H2 the list, E3 the table that reads it]`

`Lovely Support` is the clearest proof they are different axes: it is not a kind of
purchase, it is a purpose.

---

## 6. Screens

The plan is a **third lens on the Expenses home**, beside `List` and `Month`. It is not
a new tab. The home is already framed by the pay cycle and already has the lens
abstraction (`CycleLensArea`, `CycleListLens`, `CycleCalendarLens`) and a shared cycle
header (`CycleChrome`, `CyclePaging`). A plan is the same cycle seen from the other
side — what was intended, against what happened — so it shares one cycle navigator.
Two navigators that must stay in sync is the bug this avoids.

### 6.1 Plan lens anatomy

Top to bottom:

1. **Income** — the `IncomeLine` list (name · amount · *has arrived* toggle), then
   **Total Income** and **Sisa**. Sisa is the number the owner is actually looking for.
   `[→ E1]`
2. **Review notice** — present only when unreviewed Auto expenses exist (§7.3).
   One line: *"3 Auto items posted — check the amounts."* **Tappable**: it opens a
   review sheet listing each posted `Expense` with its amount and whether that amount
   matches the plan. Any line opens that `Expense` in the existing expense editor; a
   footer button clears every needs-review flag at once. `[→ E1, G2, I3]`
3. **Plan items** — sorted by **amount descending**, matching the spreadsheet. Dormant
   rows (§7.2) are collapsed into a section at the bottom. `[→ E2, F2]`
   - A **Fixed** row carries: name, amount, Category chip, Account chip, People avatars,
     a due-day badge when set, an `Auto` badge when set, and the Done control.
   - An **Envelope** row carries: name, planned amount, and progress — spent against
     planned, with the remainder called out. Overspend is marked, never blocked.
4. **Transfer checklist** — one line per Account: derived total, optional manual
   adjustment, and a *transferred* checkbox that resets each cycle. `[→ E3, I2]`
5. **Group percentages** — six rows: Group, % of Total Income, amount. Planned only.
   `[→ E3]`

Under Sisa sit **two independent annotation strips**, each in its own container and
never a fourth row of the sum — **Sisa keeps its definition and does not move as money
is spent.** Both can show at once; each hides when it does not apply.

- **`Row · Drift`** — actual money has run past the plan:
  `Σ(linked Expense − PlanItem.amount)` over done Fixed items, plus `Σ` envelope
  overspend. Reads *"Over plan so far · Rp 95.600"*. `[→ E1]`
- **`Row · Over income`** — the plan itself allocates more than income, so Sisa is
  negative. Reads *"Planned past your income — nothing is blocked"*, with no figure
  because the negative Sisa directly above already is it. `[→ I6]`

The two are different facts — one about **actuals**, one about the **plan** — so they
are separate components, not one strip with swapped copy.

Neither strip counts **unbudgeted** spending: an expense whose Category belongs to no
envelope and no Fixed item is invisible to the plan entirely (§5.2). That is a third way
real money escapes Sisa, and it is currently unreported. Left open deliberately.

### 6.1.1 Editors

Three sheets, none of which is the expense editor:

- **Plan item editor** — amount, kind (§5.1), name, Category, Account, People, and for
  Fixed only: due day and `Auto`. The field set changes with the kind, because an
  Envelope has no Account, no due day and no `Auto`. Reached by tapping a plan row.
  `[→ F1 Fixed, F3 Envelope, I8 Auto without a due day]`
- **Income line editor** — name, amount, *has arrived*. Free-typed; no Category, no
  Account. Reached from an `Add income line` row at the foot of the plan. `[→ I1]`
- **Transfer adjustment editor** — shows the derived total, takes the signed
  adjustment, and shows the resulting transfer figure. Reached by tapping a
  transfer line. `[→ I2]`

New plan items and income lines are added from rows at the **foot of the plan list**,
reusing the `New Category` pattern. The ＋ toolbar button is untouched and still logs
an `Expense` (§3.2). `[→ F2]`

### 6.1.2 Empty and edge states

- **No plan at all** — only possible for the first cycle, since every later one is
  copied forward (§7.2). Empty state plus a *Start this cycle's plan* button. `[→ I5]`
- **Negative Sisa** — the Sisa figure and the cycle header both turn red, and
  `Row · Over income` appears. Nothing is blocked (§9.3). `[→ I6]`
- **A future cycle in `List` or `Month`** — the existing empty state, unchanged. `[→ G4]`

### 6.2 What the design pass still decides

Settled by the design pass (2026-09-20), recorded here so the reasons survive:

- **The shared cycle header keeps its shape and swaps its labelled pair** — `SPENDING /
  Rp 220.000` becomes `SISA / Rp 2.000.000` while the Plan lens is active. The label
  always names the number, so no number ever changes meaning silently.
- **Envelope progress is a bar**, reusing the existing `ProportionRow` track/bar
  vocabulary. Overspend fills the track and recolours; the remainder reads *"Rp 48.300
  over"*. No rings — the app's chart language is bars.
- **The transfer checklist and percentage table sit at the foot** of the plan, after
  the item list, because that list is long.
- **A plan row is not styled like an `ExpenseRow`** — the Done control leads where a
  category icon would, so a plan reads as a checklist. The two must not look alike.
- **A plan row is two lines** — name and amount on top, chips full width beneath. IDR
  amounts are too wide to share one line with chips at 402pt.

Still open:

- How the Plan lens lays out on iPad and Mac, where the home is two-column.

---

## 7. Flows

### 7.1 Building a plan

The owner navigates forward to the next cycle before payday and opens the Plan lens.
The plan is already populated by carry-over (§7.2). They adjust amounts, add what is
new, and watch Sisa. `[→ E5 arriving, F1–F5 the whole authoring pass]`

**This requires a change to `CyclePaging`.** Today `canGoForward` stops at the present
cycle, so the next cycle cannot be reached at all — which is precisely where planning
happens. Forward paging opens up, in every lens. In a future cycle, `List` and `Month`
show the existing empty state; `Plan` shows the plan. One rule across all three lenses:
an arrow that enables and disables depending on which toggle is selected reads as a bug.
`[→ E5, F5, G4]`

`canGoBack` must also learn about plans. It currently keys off the oldest `Expense`, so
a cycle containing only a plan would be unreachable.

### 7.2 Carry-over

A new cycle's plan starts as a **full copy** of the previous cycle's — every PlanItem
and every IncomeLine, amounts included. `[→ E5]`

Rows that were Rp 0 or never completed last cycle arrive **dormant**: collapsed into a
"From last cycle" section, one tap to activate. This is the one place the app should
beat the spreadsheet rather than copy it. In the sheet those rows are kept deliberately
— they are reminders (*"don't forget Liburan Saving"*) — but they accumulate: 11 dead
rows in January, 18 by September, including `New year occasion`. On a phone that is the
whole screen. Folding them keeps the reminder and drops the clutter. `[→ F2]`

### 7.3 Completing an item

**Manual (the common case).** Ticking Done opens a **compact confirmation sheet**:
amount prefilled from the plan and ready to overwrite, date defaulting to today,
Category, Account and People carried across. Confirm, and the `Expense` is created and
linked. `[→ E4]`

The confirmation is not ceremony. Fixed amounts drift:

```
Tagihan Handphone Ibu   Jan Rp 280.000  →  Feb Rp 407.500
Tagihan Handphone       Jan Rp 220.000  →  Feb Rp 347.500
Cat Needs               Jan Rp 1.020.000 → Feb Rp 1.497.000 → Mar Rp 850.000
```

`407.500` is not a number anyone plans. It is the real bill, typed in afterwards. An
`Expense` carrying the planned figure instead would quietly poison the cycle total, the
category chart and the leaderboard, and go unnoticed for months. Storing both the
planned and the actual amount is also what makes plan-vs-actual possible at all.

**Auto.** An item marked `Auto` with a due day materialises its `Expense` on its own,
at the planned amount, with no confirmation. See ADR-0007 for why this is accepted
despite contradicting the manual path. `[→ G2]`

Two consequences the design must carry:

- **iOS does not run this in the background.** The Expense appears the first time the
  app is opened after the due day passes. Five days away means five expenses at once on
  the next launch. The review notice must read sensibly in that case. `[→ G2]`
- **Auto expenses are marked *needs review*** until the owner confirms them. The review
  notice in §6.1 is the only prompt, and it is **tappable**: it opens a sheet listing
  the posted expenses, each of which opens in the existing expense editor, plus one
  button that clears every flag. Without a route to the amount, the flag could only be
  dismissed, never acted on — and a failed autodebit or a changed amount
  (`Cicil ke Kartu Kredit` ran Rp 6.751.000 in February and Rp 4.700.000 in August)
  would stay invisible.

**Un-ticking.** Ticking Done creates an `Expense`; un-ticking **deletes it**, behind a
confirmation that names the amount and date. `[→ I4]` This is symmetric with §9.5, where deleting
the `Expense` returns the item to not-done. Unlinking without deleting was rejected: the
orphan would keep counting in its envelope and in every cycle total.

`Auto` also carries a meaning in the transfer checklist: an Auto item still contributes
to its account's line. Verified — `ke BNI Rp 7.706.000` is `Cicilan Rumah BNI`, an Auto
item. The line does not mean *"transfer this"*; it means *"make sure this account holds
enough for the debit to clear."*

### 7.4 Due days

A due day is a **day-of-month**, not a date, so carry-over brings it along for free.
Optional on every PlanItem; required for `Auto` items, which otherwise never fire — the
`Auto` switch stays inert until a due day is set. Days 29–31 clamp to the end of short
months, reusing the `PayCycle` clamp the `Payday` anchor already has. `[→ I8]`

On manual items it is a reminder only and changes no behaviour. The badge shows the
**absolute day** (*"Due 25"*), which is what carry-over stores, and switches to the
relative form (*"due in 3 days"*, in accent) once the day is within three days of today.
It never reads relative in a cycle that has not started, where a countdown is meaningless.
`[→ component `PlanChip · Due` / `Due soon`]`

### 7.5 Payday

The owner works down the transfer checklist with six banking apps open. Each line gives
the amount and a checkbox. `[→ G1 payday morning, E3 the checklist, I2 the adjustment]` The manual adjustment covers cases like the spreadsheet's
`ke Superbank −Rp 700.000`: money already sitting in the account, so transfer less.

The adjustment is a number inside one plan. The app never claims to know a balance —
it could not, since money moves without passing through this app.

---

## 8. Changes to existing behaviour

| Area | Change | Drawn in |
|---|---|---|
| `CyclePaging.canGoForward` | Stops at the present cycle today. Opens up, all lenses. | `E5`, `F5`, `G4` |
| `CyclePaging.canGoBack` | Must consider plans, not just the oldest `Expense`. | — paging logic (§11.2) |
| Expenses home | Gains a third lens in the `List \| Month` toggle. | `E1`; component `SegmentedToggle · 3-lens` |
| `Category` | Gains an optional `Group`, chosen in the Category editor. | `H4` |
| Manage | Gains a **Groups** section — `Group` is user data, so it gets the same list, rename, delete and duplicate-name handling as Category, Person and Account. | `H1`, `H2`, `H3`; the duplicate-name prompt is the existing `B6`, reused unchanged |
| `Person` | **Widens** to cover people money is sent to, not only companions. ADR-0006. | — no UI change; the People picker in `F1` is the existing one |
| People leaderboard | Now mixes both meanings, by decision. ADR-0006. | — no UI change (§11.2) |
| `Expense` | Gains an optional link back to the Fixed `PlanItem` that created it. | stored, not surfaced — see §11.3 |
| `docs/design-brief.md` | Its "has NO income / NOT a budget app" claim is now wrong. | — document, already annotated |

Unchanged, deliberately: the ＋ add-expense flow, the expense editor, Insights, Search,
and every existing chart. **Manage is the one exception** to its own earlier listing: it
gains a Groups section and a Group row inside the Category editor, because §9.6 requires
Group names to be de-duplicated in the UI "exactly as for Category and Person", which is
only possible if the owner can create and rename them. Nothing else in Manage changes.

---

## 9. Explicit assumptions

Consequences rather than choices, written down so none of them is silent:

1. Plan rows sort by **amount descending**; dormant rows collapse at the bottom. `[→ E2, F2]`
2. **Past plans are never locked.** A closed cycle's plan stays editable; there is no
   book-closing step. `[→ nothing to draw — the absence of a step, §11.2]`
3. **Envelope overspend and a negative Sisa are visual only.** Nothing is ever blocked.
   `[→ E2 overspend, I6 negative Sisa]`
4. **Deleting a PlanItem does not delete its Expense** (ADR-0001, nullify). The expense
   survives as history; the link is dropped. `[→ I7]`
5. **Deleting an Expense returns its PlanItem to not-done.** The reverse also holds:
   **un-ticking Done deletes the linked Expense**, behind a confirmation (§7.3).
   `[→ I4 for un-ticking; the other direction is silent, §11.2]`
6. **CloudKit rules apply to every new model**: all properties optional or defaulted,
   all relationships optional, no unique constraints (ADR-0002). De-duplication of
   Group names is a UI concern, exactly as for Category and Person.
   `[→ H3, which reuses the existing duplicate-name prompt from B6]`
7. **The schema change is a new `VersionedSchema` + `MigrationStage`**, per the note in
   `ExpenseKuSchema.swift`. V1 is never edited.
8. **Money stays `Decimal`.** Percentages are display-only and never stored.
9. **Sisa never subtracts expenses.** `Total Cost` sums `PlanItem.amount` — the planned
   figures — so Sisa is stable through a cycle and moves only when the plan is edited.
   Actual spending is the `List` lens total. The two annotation strips (§6.1) report the
   gap; neither changes Sisa, and neither counts unbudgeted spending. `[→ E1, G3, I6]`
10. **`Group` is user data, not a fixed enum.** The six spreadsheet buckets are seed
   values, not a closed set. `[→ H2, H3]`

---

## 10. Decision log

Every entry below was settled in a grilling session on 2026-09-20 and is traceable to
the spreadsheet or the codebase. Four were decided against the recommendation put to the
owner; they are marked, because a future reader should know they were argued and chosen,
not overlooked.

| # | Decision | Drawn in |
|---|---|---|
| 1 | `PlanItem` and `Expense` are two linked entities; Done creates the Expense | `E4` creates it · `I4` undoes it |
| 2 | Two kinds of PlanItem: **Fixed** and **Envelope** | `F3`, `E2` |
| 3 | Two-level vocabulary: **Category** (fine, existing) + **Group** (coarse, new) | `H4`, `E3` |
| 4 | An Envelope scopes to a **set of Categories**; one Category per envelope per plan | `F4` |
| 5 | One plan per pay cycle, existing `Payday` anchor, existing cycle naming | `E1` |
| 6 | Income lives **only inside a plan** — free-typed lines, carried over | `I1`, `E5` |
| 7 | Carry-over copies everything; dormant rows fold into a collapsed section | `E5`, `F2` |
| 8 | Done opens a **compact confirmation sheet**; planned and actual both stored | `E4`; both amounts visible in `E2` |
| 9 | `Auto` items **materialise their own Expense** on the due day — *owner override* | `G2` |
| 10 | Due day is a **day-of-month**, optional everywhere, clamped at month end | `F1`, `I8` |
| 11 | Auto-created expenses are flagged **needs review** | `G2`, `I3` |
| 12 | Transfer checklist: derived Σ + per-account checkbox + manual adjustment | `E3`, `I2` |
| 13 | **No priority tiers** in v1 — *owner override* | — an absence |
| 14 | Plan is a **third lens on the home**, not a fourth tab | `E1` · `SegmentedToggle · 3-lens` |
| 15 | Forward cycle paging **opens up**, in every lens | `E5`, `G4` |
| 16 | Percentage table shows **planned only** | `E3` |
| 17 | **No importer**; one cycle entered by hand | `I5` |
| 18 | `PlanItem` carries **People**, passed to the Expense — *owner override* | `F1`, `E2` |
| 19 | The People leaderboard **mixes** both meanings of Person — *owner override* | — no UI change |
| 20 | `Group` gets a **full Manage section**, not inline creation or a fixed enum | `H1`, `H2`, `H3` |
| 21 | The review notice is **tappable** — it opens a review sheet over the posted expenses | `I3` |
| 22 | Un-ticking Done **deletes** the linked Expense, behind a confirmation | `I4` |
| 23 | The due badge is **absolute, turning relative within three days** | `I8` · `PlanChip · Due soon` |
Entries 20–23 were settled on 2026-09-20 during the design pass, when drawing the
screens surfaced questions §§6–9 had not answered. See `design/ExpenseKu.pen`,
flows E–I.

---

## 11. Design traceability

Every screen is a top-level frame in **`design/ExpenseKu.pen`**, page `02 · Pages · iPhone`.
Flows A–D are the app as it already ships; **E–I are this feature** and are unbuilt design.
Components live on page `01 · Design System`, group **`Cycle plan`** (25 components).

### 11.1 Screen → what it settles

| Frame | Covers |
|---|---|
| **E1** · Plan lens — income & Sisa | §6.1.1–2, §6.1 drift strip, §6.2 header swap |
| **E2** · Plan items | §6.1.3, §9.1 sort + dormant fold, §9.3 envelope overspend |
| **E3** · Payday — transfers & share | §6.1.4, §6.1.5, §7.5 |
| **E4** · Done → confirmation sheet | §7.3 manual path, decision 8 |
| **E5** · Next cycle — carried over | §7.1 forward paging, §7.2 carry-over |
| **F1** · Adjust a carried-over amount | §6.1.1 plan item editor (Fixed field set) |
| **F2** · Wake what matters again | §7.2 dormant rows, §6.1.1 add-rows at the foot, §3.2 |
| **F3** · New item — Fixed or Envelope | §5.1 two kinds, §6.1.1 Envelope field set |
| **F4** · Envelope categories | §5.2 one Category per Envelope per plan |
| **F5** · October is ready | §7.1 a plan that exists before its cycle |
| **G1** · Payday — the cycle opens | §7.5, income `hasArrived` |
| **G2** · Five Auto items landed at once | §7.3 Auto + lazy materialisation, ADR-0007 |
| **G3** · The same cycle in List | §3.3 planned money never shows as spent; §8 `List` unchanged |
| **G4** · A future cycle in List | §7.1 empty state in a future cycle |
| **H1** · Manage — gains Groups | §8 Manage gains a Groups section |
| **H2** · Groups | §8, §9.10 Group is user data |
| **H3** · Edit Group | §9.6 name de-duplication, rename/delete |
| **H4** · Edit Category — gains Group | §5.3, §8 Category gains an optional Group |
| **I1** · Income line editor | §6.1.1, decision 6 free-typed income |
| **I2** · Transfer adjustment | §6.1.1, §7.5 manual adjustment, decision 12 |
| **I3** · Review the Auto items | §7.3 needs-review, decision 21 |
| **I4** · Un-tick Done — confirm | §7.3 un-ticking, §9.5 |
| **I5** · The very first plan | §6.1.2, §4 no importer |
| **I6** · Negative Sisa | §6.1.2, §9.3, `Row · Over income` |
| **I7** · Delete a plan item | §9.4 the Expense survives (ADR-0001 nullify) |
| **I8** · Auto needs a due day | §7.4 due day required for Auto |

### 11.2 Requirements with no screen, by design

These are logic or data rules with nothing to draw. Listed so their absence is not read
as an omission:

| Requirement | Why nothing is drawn |
|---|---|
| §5.2 Expense linked to a Fixed item is excluded from every envelope | Invisible accounting rule |
| §5.2 An expense in no envelope is simply unbudgeted | Invisible; it still counts in cycle spending |
| §7.1 `canGoBack` must consider plans | Paging logic; the arrow already exists |
| §8 `Person` widens; leaderboard mixes | ADR-0006 needs no schema or UI change; People picker already exists |
| §8 `Expense` gains a link to its `PlanItem` | Stored, not surfaced — see the open question below |
| §9.2 Past plans are never locked | The absence of a book-closing step |
| §9.6 CloudKit rules · §9.7 VersionedSchema · §9.8 `Decimal` | Implementation constraints |
| §9.5 Deleting an Expense returns its item to not-done | Happens in the existing expense editor; the plan row updates silently |

### 11.3 Not drawn — still open

| Item | Status |
|---|---|
| **iPad / Mac two-column layout** (§6.2) | Deferred by the owner, 2026-09-20 — the design is still iterating on iPhone |
| Does a Fixed item's **name become the created Expense's note**? | `G3` assumes yes. Without it the ledger shows five rows called only "Cicilan"/"Hiburan". Not yet a PRD decision |
| Should a **needs-review** Expense be marked in the `List` lens too? | `G3` leaves `ExpenseRow` untouched per §6.1. A dismissed notice then hides a wrong amount permanently — the risk ADR-0007 accepts |
| `Month` lens in a cycle with a plan | Unchanged and symmetric with `G3`; drawn only for `List` |
| **Unbudgeted spending is invisible to the plan** (§5.2) | Neither annotation strip reports it. An expense in no envelope and no Fixed item moves the `List` total only — Sisa and both strips stay silent. Closing it would mean a third strip; not yet a PRD decision |

### 11.4 Components added by this feature

`Cycle plan` group, page `01 · Design System`:

- **Rows** — `PlanFixedRow`, `PlanEnvelopeRow`, `IncomeRow`, `TransferRow`,
  `GroupShareRow`, `DormantRow`
- **Controls** — `DoneCheck` (Todo / Done / Auto / Auto posted / Envelope),
  `SegmentedToggle · 3-lens`, `PlanKindToggle` (+ `· Envelope`), `FormRow · Toggle`
- **Chips** — `PlanChip` (Category / Account / Due / Due soon / Auto / Review)
- **Blocks** — `PlanTotals` (incl. `Row · Drift` and `Row · Over income`),
  `ReviewNotice`, `DormantHeader`
- **Pickers** — `PickerRow · Category Multi`, `PickerRow · Claimed`

Everything else is reused unchanged from the shipping design system.
