# PRD — Paid elsewhere

Status: Built
Date: 2026-10-28 · grilled, design approved and built the same day (flow AE)
Owner: Randy Efan

Companion documents: `docs/prd/envelope-detail.md` (the sheet this adds a section to, and its
hand-off rule §4.6), `docs/prd/partial-transfer.md` (the sheet pattern reused here, §6),
`docs/prd/envelope-assignment.md` (where an expense counts, §4.1; paying ahead, §4.10),
`docs/prd/payday-planning.md` (Funded, §7.6), `CONTEXT.md` (ubiquitous language),
`docs/adr/0005-plan-and-ledger-are-separate.md`, `docs/adr/0013-paid-elsewhere-is-a-reported-move.md`,
and **`design/ExpenseKu.pen`**, page `02 · Pages · iPhone`, **Flow AE** (moved there from
`05 · Proposals` once built). Frame references appear inline as `[→ AE2]`.

---

## 1. What this is

An Envelope may name an Account: "Travelling" is kept in **Jago**. On payday the owner moves
the envelope's money there and marks it Funded. On the trip itself, though, the owner pays a
Grab or a hotel with **CC Danamon**, for the card's points. The expense is logged honestly —
Account CC Danamon, assigned to Travelling — and the envelope's bar counts it, because an
envelope never looks at an expense's Account (`envelope-assignment.md` §4.1).

What the app does not say is that the money for that Grab is still sitting in Jago, while the
bill for it lands on the card next month. Two things go wrong:

1. **Paying twice.** Next month's salary pays the whole card bill, though the trip's share was
   set aside in Jago already.
2. **Stranded money.** The envelope reads as spent, Jago's balance never fell, and after a few
   trips the owner no longer knows how much of Jago still belongs to Travelling.

This feature adds a **PAID ELSEWHERE** section to the envelope's detail: one row per other
Account the envelope's expenses were paid from, with how much of it the owner has already
**moved from Jago**. The owner moves the money in their banking app when the card bill comes,
and records it here through a sheet like the Transfer checklist's. `[→ AE1]`

## 2. Goals

1. Say, per Account, how much of an envelope was paid from somewhere other than the envelope's
   own Account.
2. Let the owner record, expense by expense, which of it they have moved back from the
   envelope's Account — so a card statement that cuts off mid-trip can be settled in rounds.
3. Keep the figure right on its own when an expense is added after a round: a new Grab makes
   the row owe again, with no tick to undo.
4. Change nothing the plan computes: Sisa, totals, Funded, the transfer checklist.

## 3. Non-goals

- **Balances.** The app still does not know what is in Jago or on the card (CONTEXT.md
  *Account*). "Moved" is a fact the owner reports, like Funded.
- **Linking to the card bill.** Next cycle's `Cicil ke Kartu Kredit` (or however the owner pays
  the card) is not touched or reduced. Lowering it is the owner's call, by hand.
- **A reminder in the current cycle.** The section lives only in the envelope's detail; a past
  cycle's envelope is reached by paging back (`envelope-detail.md` decision H). `[→ AE1]`
- **A change to the Plan lens.** The envelope row, its caption and its ＋ stay as they are.
- **Showing "moved" anywhere else.** Expense rows, the expense editor, the List lens, Search
  and Insights do not show it.
- **Unassigned expenses.** An expense with no Account is taken as paid from the envelope's own
  Account (§4.2).

---

## 4. The rules

### 4.1 Paid elsewhere

An expense is **paid elsewhere** when all of these hold:

| Condition | Why |
|---|---|
| The envelope counts it — it is in `EnvelopeDetail.expenses`: its own cycle's, or paid early from an earlier cycle | the section must agree with the list under it |
| The envelope has an Account | without one there is nowhere to "move from" |
| The expense has an Account | §4.2 |
| The two Accounts differ | paid from the envelope's own Account needs no move |

An envelope with no Account shows no section at all. Neither does an envelope none of whose
expenses is paid elsewhere. `[→ AE1]`

### 4.2 Unassigned counts as the envelope's own

An expense with no Account is **not** paid elsewhere. Accounts are optional at entry and quick
entries skip them; listing them would make tasks that are not real. Setting an Account on it
later brings it into the section if that Account differs.

### 4.3 The section

Placed **directly under the card**, above the expense list and the Set aside section. Header
**`PAID ELSEWHERE`**, in `SectionHeaderText`. One row per Account, drawn like `TransferRow · bank`: check, the Account's plate, the name and
amount on one line, the caption under them. `[→ AE1]`

| Part | Content |
|---|---|
| Check | derived from the Account's expenses: ◯ none moved · ◐ some moved · ✓ all moved — the `DoneCheckFace` glyphs the transfer line uses |
| Title | the Account's name, with its icon or bank logo (`bank-logos.md`) |
| Caption | ◯ **`Move from Jago`** · ◐ **`Rp 48.000 to move · Rp 515.000 moved`** · ✓ **`Moved from Jago`** |
| Amount | Σ of the Account's paid-elsewhere expenses, all of them — not what is left to move, which the caption carries |

The whole row is one Button and opens that Account's sheet (§4.5). There is no tap on the
check itself.

### 4.4 Order

1. Rows with something to move, by **amount to move ↓**, then name.
2. Rows with everything moved, by amount ↓, then name.

A ✓ row stays in the section, so a move can be undone from its sheet. A state change moves a
row to its new place. `[→ AE1, AE4]`

### 4.5 The sheet

Reached from a row through the envelope detail's hand-off (`envelope-detail.md` §4.6): the
detail closes, the sheet opens, and the detail reopens when the sheet closes. A `.large` sheet,
the pattern of `partial-transfer.md` §6: `[→ AE2]`

| Part | Content | Shown when |
|---|---|---|
| Title | the plate of the Account that paid, then **`Move from Jago`**, subtitle **`to CC Danamon`**; a ✕ glass button closes it and records nothing | always |
| **`TO MOVE · k OF n`** | each not-moved expense: a `SelectionCircle`, its note (or Category when the note is empty), caption `27 Oct · Sewa`, its amount. An unchosen row stays in place and greys its amount | something is not moved |
| Figures | a card with **`Move now`**, bold, in the accent: Σ of the chosen. With everything moved it reads **`Total`** in the text colour, Σ of all. No Adjustment row: this is not a transfer line | always |
| Button | **`Moved from Jago`**, a full-width `SavePill` under the figures; disabled with nothing chosen | something is not moved |
| **`ALREADY MOVED`** | each moved expense: a ✓ (`DoneCheck · Done`), its note, caption in the secondary colour, amount in the secondary colour. The **whole row** is a Menu's label, marked by a trailing `⋯` | something is moved |

With everything moved, `TO MOVE` and the button are gone and the sheet opens on
**`Everything on BCA is moved.`** `[→ AE6]`

#### 4.5.1 Choosing and recording

- Opening the sheet chooses **every** not-moved expense. `[→ AE2]`
- Tapping a row toggles it; `Move now` follows. `[→ AE3]`
- A row's name is the expense's note, or its Category when the note is empty; its caption is
  `28 Oct · Sewa` (date · Category). No Account: the sheet's title already names it.
- Rows order by **date ↑** (the order a card statement lists them), then amount ↓, then note.
- **`Moved from Jago`** marks every chosen expense moved and closes the sheet. `[→ AE3 → AE4]`
- In `ALREADY MOVED`, the Menu offers **`Not moved yet`** (sub-line `Back to To move`, an undo
  glyph). It clears the mark with no confirmation; the row goes to `TO MOVE`, **not chosen**,
  and the sheet stays open. `[→ AE5]`

### 4.6 What is stored

One flag per Expense, **`isMovedFromEnvelope`** (schema V7, defaulted `false`). The row's
check, its caption and its amounts are derived from the flags of its expenses every time; there
is no per-Account or per-envelope record. A new paid-elsewhere expense starts not moved, so the
row owes again by itself. `[→ AE4]`

| Change to a moved expense | Flag afterwards |
|---|---|
| Amount, note, date (staying in the envelope), Category, People edited | kept |
| Account changed or cleared | cleared |
| Envelope changed — another envelope, by category, No envelope | cleared |
| Leaves the envelope another way (a date change past its cycle, the envelope deleted) | kept but unread; cleared only by the two rows above |
| Deleted | gone with it |
| The envelope's own Account changed (Jago → BCA) | kept; captions follow the new name, and expenses on BCA drop out of the section |

---

## 5. Lifetime and interactions

| Event | Afterwards |
|---|---|
| Sheet closed with ✕ or a swipe | nothing changed; the detail reopens |
| `Moved from Jago` | the chosen expenses are moved, stored and synced; the detail reopens with the row's new state |
| Sheet opened again | every not-moved expense chosen again |
| App relaunched | rows read their expenses, unchanged |
| Expense added to the envelope, paid elsewhere | the row appears or turns ◐ / ◯ |
| Carry-over to a new cycle | nothing to reset: the flags live on expenses, which are not carried over |
| Paging to the trip's cycle (`‹`) and opening its envelope | the section works there, as the detail does |

| Neighbour | Interaction |
|---|---|
| Card, bar, from-earlier caption | unchanged; the section adds nothing to `EnvelopeProgress` |
| Envelope Funded (`in Jago`) | independent; Funded says the money reached Jago, this says some of it left again |
| Transfer checklist, Sisa, totals, Group shares | unaffected |
| Paid early, set aside | paid-early expenses are listed like the envelope's own; set-aside lines are money, not spending, and never appear here |
| Plan filter, expense filter, plan sort | do not reach the detail (`envelope-detail.md` §3) |

## 6. Unaffected

- **`EnvelopeClaims`, `EnvelopeSpend`, `EnvelopeProgress`** — read, never changed.
- **The Plan lens** — the envelope row, its ＋ menu and captions.
- **Expense rows and the editor** — no new field shown.
- **ADR-0005** — the plan is still not a ledger: no Expense is created for a move, and the
  Account stays a label.

---

## 7. Sample data · `-seedPlanData paid-elsewhere`

The `-seedPlanData travelling` plan, with **Travelling Rp 2.000.000 kept in Jago**, Funded.
The trip's expenses, all on one day of the current cycle:

| Expense | Category | Account | Paid elsewhere | Seeded moved |
|---|---|---|---|---|
| Nasi Padang Bandung | Makan 85.000 | Cash | yes | no |
| Bensin ke Bandung | Bensin 150.000 | Jago | no — the envelope's own | — |
| Hotel Bandung | Sewa 450.000 | CC Danamon | yes | no |
| Grab ke hotel | Transport 65.000 | CC Danamon | yes | no |
| Grab ke stasiun | Transport 48.000 | CC Danamon | yes | no |
| Oleh-oleh | Makan 120.000 | — Unassigned | no (§4.2) | — |
| Tiket Kawah Putih | Hiburan 35.000 | BCA | yes | **yes** |

Travelling: Rp 953.000 of Rp 2.000.000 → **Rp 1.047.000 left**, unchanged by this feature.

| Frame | PAID ELSEWHERE reads |
|---|---|
| AE1 | ◯ CC Danamon Rp 563.000 `Move from Jago` · ◯ Cash Rp 85.000 `Move from Jago` · ✓ BCA Rp 35.000 `Moved from Jago` |
| AE3 → AE4 | Grab ke stasiun left unchosen: ◯ Cash Rp 85.000 · ◐ CC Danamon Rp 563.000 `Rp 48.000 to move · Rp 515.000 moved` · ✓ BCA Rp 35.000 |

Unit test only: Travelling with no Account → no section; Oleh-oleh given Account CC Danamon →
CC Danamon reads Rp 683.000.

---

## 8. Decision log

Settled in a grilling session on 2026-10-28. The owner took every recommendation; there are no
owner overrides. Entries D1–D7 are defaults stated at the gate and confirmed with it; entries
8–15 are design calls made while drawing flow AE and approved at the design gate the same day.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Shown **only in the envelope's detail**; the Plan lens row is unchanged — not a row caption, not a summary without a tick | `AE1` |
| 2 | **Unassigned** expenses count as paid from the envelope's own Account and are not listed | `AE1` |
| 3 | "Moved" is stored **per Expense**; the Account row's ◯ / ◐ / ✓ is derived, so a new expense makes it owe again — not one tick per Account, not a stored amount | `AE4` |
| 4 | Recording goes through a **sheet in the pattern of flow AD**: `TO MOVE` all chosen, `Moved from Jago`, `ALREADY MOVED` with `Not moved yet`; reached by the detail's close-and-reopen hand-off | `AE2`–`AE5` |
| 5 | **No reminder** in the current cycle; the trip's cycle is reached by paging back | — an absence |
| 6 | Words: **`PAID ELSEWHERE`**, `Move from Jago`, `Rp X to move · Rp Y moved`, `Moved from Jago`; CONTEXT.md gains **Paid elsewhere** | `AE1`, `AE2` |
| 7 | The section sits **directly under the card** | `AE1` |
| D1 | An envelope with no Account shows no section | — unit test |
| D2 | Paid-early expenses are included | — unit test |
| D3 | Rows with something to move first, by amount to move ↓; all-moved rows after, and kept | `AE1`, `AE4` |
| D4 | The flag survives an amount edit; it is cleared when the expense's Account or envelope changes | — unit test |
| D5 | Expense rows and the editor do not show the flag | — an absence |
| D6 | Sisa, Funded, the transfer checklist and totals are untouched; no filter reaches the section | — |
| 8 | A section row is drawn like `TransferRow · bank`: check, plate, name and amount, caption | `AE1` |
| 9 | The row's amount is the Account's whole total; what is left to move is in the caption | `AE4` |
| 10 | The sheet's plate is the Account that paid; the title names the envelope's Account (`Move from Jago`), the subtitle the paying one | `AE2` |
| 11 | The figures card has no Adjustment row | `AE2` |
| 12 | A sheet row is note (or Category) with `date · Category`, no Account | `AE2` |
| 13 | A moved expense shows `DoneCheck · Done`; the section headers keep it apart from a chosen `SelectionCircle`, as in flow AD decision 13 | `AE5`, `AE6` |
| 14 | A moved row's caption is secondary, not accent: moved is not "in an account" | `AE5` |
| 15 | The card shows the envelope's Account chip and `in Jago`, as the code already does; only the DS component lacked it | `AE1` |
| D7 | Its own PRD and ADR-0013 (the "transfers between accounts" non-goal still holds: this is a checklist, not a ledger); `envelope-detail.md` gets an "amended by" note | — |

---

## 9. Design traceability

Page `02 · Pages · iPhone`, **Flow AE · Paid elsewhere**. Components `PaidElsewhereRowView`,
`PaidElsewherePickRow` and `PaidElsewhereMovedRow` live on `01 · Design System`, group
`Cycle plan`, row `Paid elsewhere`; the sheet reuses `TransferFigureRow` and
`TransferRecordButton`.

| Frame | Covers |
|---|---|
| **AE1** · Travelling's detail — PAID ELSEWHERE | §4.1, §4.3, §4.4, decisions 1, 2, 6, 7 |
| **AE2** · Move from Jago to CC Danamon — opened | §4.5, §4.5.1 default and order, decision 4 |
| **AE3** · Grab ke stasiun unchosen | §4.5.1 toggle, `Move now` |
| **AE4** · Back on the detail | §4.4 reorder, §4.6 derived ◐, decision 3 |
| **AE5** · CC Danamon again — `Not moved yet` | §4.5 `ALREADY MOVED`, §4.5.1 Menu |
| **AE6** · BCA — everything moved | §4.5 all-moved sheet |

### 9.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| The editor's assignment falls back to By category when a date change leaves the envelope's cycle (`envelope-assignment.md` §4.4) | That is an envelope change, so the mark clears. §4.6's "kept but unread" holds only when the envelope leaves without the expense's choice changing (the envelope deleted) | `EnvelopeChoice.apply` |
| How a row reaches its sheet | The row carries the Account's id; the detail resolves it and hands off `EnvelopeDetailAction.paidElsewhere`, a new `EnvelopeSheet` case, under §4.6 | `EnvelopeDetailSheet`, `ExpensesView+EnvelopeDetail` |
| `Not moved yet` must put the expense back at once | The sheet queries the cycle's expenses and rebuilds the row through `EnvelopeDetail`, as the detail does | `PaidElsewhereSheet` |
| The caption's date | Follows the device's locale like every other short date: `28 Oct` in en-GB or id, `Oct 28` in en-US | `PaidElsewhereMember` |
| ◯ / ◐ / ✓ | `TransferFill.of(inCount:of:)`, shared with the transfer line, so the glyphs cannot drift apart | `TransferFill`, `PaidElsewhereRow` |
| Upgrade safety | `Fixtures/PlanV6.store` was written by the V6 code before the model changed; `StoreMigrationTests` opens it, finds nothing moved, and keeps a move across relaunches | `StoreMigrationTests` |
| The derivation | Pure and tested against §7's own sample, one test per rule | `PaidElsewhere`, `PaidElsewhereRow`, `PaidElsewherePick`, `PaidElsewhereTests` |
