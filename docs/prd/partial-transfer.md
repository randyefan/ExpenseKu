# PRD — Transferring part of an Account's line

Status: Accepted
Date: 2026-10-24 · design approved the same day (flow AD)
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Transfer checklist §6.1.4, §7.5 and
Funded §7.6 this changes; decision 25 is reversed here), `docs/prd/bank-logos.md` §5.6.4 (the
line's plate and caption), `docs/prd/plan-sort.md` §4.1 (due day in cycle), `CONTEXT.md`
(ubiquitous language), and **`design/ExpenseKu.pen`**, page `05 · Proposals — not built`,
**Flow AD**. Frame references appear inline as `[→ AD2]`.

The flow is AD, not AC: Flow AA already names its frames AC1–AC4, and `bank-logos.md` cites them.

---

## 1. What this is

The Transfer checklist gives each Account one line: the sum of every plan item paid from or
kept in it, plus a manual adjustment, and a ✓ Sent tick the owner sets by hand. That number
assumes the whole income is in.

A plan often has two income lines (`Gaji Fulltime`, `Tunjangan`), and they do not land on
the same day. With only one in, the owner moves money for some items now and the rest later,
so a line's whole figure is not what they transfer, and the one tick cannot say "BCA is half
done".

This feature lets the owner open a line, choose which of its items to move now, see the
total of that choice, and record it. Recording uses the per-item **Funded** state that
already exists (`payday-planning.md` §7.6): the chosen items become ◐ *in the account*. The
line then reads off its items: what is in, what is still to go, and its tick follows.

## 2. Goals

1. On payday with part of the income in, transfer exactly the chosen items' total, without
   adding it up by hand.
2. See, per Account, what is already in and what is still to go, after any number of rounds.
3. Keep one truth: the line's tick, the plan rows' ◐, and the bank headers (sorted by Account)
   all read the same item states and can never disagree.
4. Keep the normal payday (all income in) at two taps per line.

## 3. Non-goals

- **Tying items to an income line.** Which income pays which item is not modelled; the owner
  chooses each payday.
- **Moving part of one item.** An item is in or not; there is no split amount.
- **Remembering a choice.** Only what is recorded (◐) persists; an unrecorded choice is gone
  when the sheet closes.
- **A history of rounds** ("Rp 2.200.000 on 25 Oct, Rp 547.300 on 1 Nov").
- **Balances.** The app still never knows what an Account holds (§4 of `payday-planning.md`).

---

## 4. The sample

Every frame, and the tests, use the Plan lens's `normal` sample (`DebugPlanSeed`), payday 25,
cycle 25 Oct → 24 Nov. `Gaji Fulltime` Rp 20.000.000 has arrived; `Tunjangan` Rp 2.000.000
has not.

| Line | Items (amount · due · state) | Adjustment | Stored tick |
|---|---|---|---|
| **BNI** | Cicilan Rumah BNI 7.706.000 · 20 · Auto ◯ | — | Sent |
| **CC Danamon** | Cicil ke Kartu Kredit 4.700.000 · 25 · Auto; Netflix 130.000 · 2 · Auto; Apple Service 59.000 · 18 · Auto; Vidio 49.000 · 18 · Auto — all ◯ | — | Sent |
| **BCA** | Kos 2.200.000 · 5 ◯; Gym membership 300.000 · 1 · Auto ◯; Listrik Kos 247.300 ◯ | — | — |
| **Mandiri** | Tarisa Needs 1.500.000 ◯; Kirim buat Ibu 1.000.000 ◯; Tagihan Handphone Ibu 326.500 ✓ Done | −700.000 | — |
| **Cash** | Bayar parkir motor SQ 650.000 ◯ | — | — |

The story: with only the salary in, the owner moves **Kos** to BCA now (Rp 2.200.000) and
leaves Gym and Listrik for when Tunjangan lands.

---

## 5. The line

### 5.1 State

A line's state is derived from its items' effective states (`payday-planning.md` §7.6), the
same reading as the bank header's `AccountGroupState`. An item is **in** when it is Funded or
Done. `[→ AD1]`

| State | When | Check | Amount | Caption |
|---|---|---|---|---|
| **Nothing in** | every item Todo | ◯ | Σ items + adjustment, never below 0 | unchanged: `3 items · Due 1, 5`, then its notes (`bank-logos.md` §5.6.4) |
| **Part in** | some in, some Todo | ◐ `DoneCheck · Funded` | Σ of the **Todo** items | `1 item in · 2 to go · Due 1` — due days of the Todo items only, then the paid-early / set-aside note. No adjustment note: the adjustment is taken (§5.3) |
| **All in** | every item in | ✓ | Σ items + adjustment, never below 0 | unchanged |

`[→ AD1 Mandiri part in, BNI all in; AD4 BCA part in]`

- The line's ✓ is no longer stored or tapped. `TransferLine.hasTransferred` is read once by
  §8 and then never written; `TransferLine` keeps only the adjustment.
- Order of lines: unchanged (planned total ↓, name). A line does not move when its state
  changes.
- Header: `TRANSFER CHECKLIST · 2 OF 5 SENT` counts **All in** lines. A part-in line is not sent.
- VoiceOver: one button, label `Transfer to BCA`, value `Nothing in yet` · `1 of 3 in` · `All in`.

### 5.2 Tap

The whole line is one Button. It opens the line's sheet (§6). There is no tap that changes
state from the checklist itself. `[→ AD1 → AD2]`

### 5.3 The adjustment

The adjustment still belongs to the Account and is still one number (`payday-planning.md` §7.5).
It counts in the **first round**: while every item of the line is Todo, `Transfer now`
includes it; once any item is in, it is taken and no later round counts it.

Because a Done item is in, Mandiri's −700.000 in the sample is already taken: Tagihan Handphone
Ibu was paid from Mandiri. Its line reads **Part in · Rp 2.500.000**. `[→ AD1, AD6]`

---

## 6. The sheet

A `.large` sheet titled with the Account: the Account's plate, then **`Transfer to BCA`**. A
✕ glass button on the leading side closes it and records nothing. `[→ AD2]`

### 6.1 Sections

| Section | Rows | Shown when |
|---|---|---|
| **`TO SEND · 3 OF 3`** | each Todo item: a `SelectionCircle` (on / off), the name, a caption, the amount — net of paid early / set aside for an Envelope. The caption joins the item's Category (`Envelope` for an Envelope), `Auto`, and `Due 1` with ` · `, each only when it applies. An unchosen row keeps its place and greys its amount | the line has a Todo item |
| **Figures** | a card: `Adjustment` with a chevron (tap → the adjustment editor, `I2`), its value `None` when 0, signed and red when negative, with the sub-line `Taken with the first transfer` once taken; then `Transfer now`, bold, in the accent | always; with every item in, the second figure reads `Total` in the text colour |
| **Button** | `Moved to BCA`, a full-width `SavePill` under the figures | the line has a Todo item |
| **`ALREADY IN BCA`** | each in item: its state's check (◐ Funded, Auto funded, Envelope funded, or ✓), the name, a caption, the amount in the secondary colour. A Funded row's caption is the plan row's own words in the accent (`in BCA`, `covered in BNI`); the **whole row** is a Menu's label, marked by a trailing `⋯` glyph. A Done row's caption is `‹Category› · paid`, its amount the planned one, and it has no Menu | the line has an in item |

`[→ AD2 nothing in, AD5 part in, AD6 Done + adjustment taken, AD7 all in]`

- `TO SEND · k OF n` counts the chosen of the Todo items.
- With every item in, `TO SEND` and the button are gone; the sheet opens on
  **`Everything for BNI is in.`** and the figures read the line's `Total`. `[→ AD7]`

### 6.2 Choosing

- Opening the sheet chooses **every Todo item**. `[→ AD2]`
- Tapping a row toggles it. `Transfer now` = Σ chosen + the adjustment if not yet taken, never
  below 0. `[→ AD3]`
- Rows order by **due day in cycle** (`plan-sort.md` §4.1), undated after them, ties and the
  undated tail by amount ↓ then name. In the sample BCA reads Gym (1) · Kos (5) · Listrik.

### 6.3 Recording

- **`Moved to BCA`** sets every chosen item Funded and closes the sheet. When every chosen
  item is Auto it reads **`Covered in BNI`** (the Auto menu's words, §7.6). Disabled with
  nothing chosen. `[→ AD3 → AD4]`
- In `ALREADY IN`, a ◐ row's Menu offers **`Not moved yet`** (sub-line `Back to To send`, an
  undo glyph; an Auto row says **`Not covered yet`**), which clears Funded with no confirmation.
  The row moves to `TO SEND`, **not chosen**, and the sheet stays open. `[→ AD5]`
- A Done row is read-only. Undoing Done stays where it is today (the item's own check, `I4`).

---

## 7. Lifetime and interactions

| Event | Afterwards |
|---|---|
| Sheet closed without recording | nothing changed |
| `Moved to …` | the chosen items are Funded, stored and synced like any ◐ |
| Sheet opened again | every Todo item chosen again |
| App relaunched | the line reads its items, unchanged |
| A ◐ set or cleared from the plan row's own Menu | the line follows; it is the same `isFunded` |
| An item's Account changed or cleared | it leaves this line (and is Todo without an Account, §7.6) |
| A Done item's Expense deleted | it falls back to ◐, still in |
| Carry-over to a new cycle | every item starts Todo (§7.2), so every line starts **Nothing in**; the old plan keeps its states |
| Paging to an earlier plan (`‹`) | its lines read its own items; the sheet works there too |

| Neighbour | Interaction |
|---|---|
| Funded filter | hides the checklist, as before |
| Funded notice | after a partial round it appears for the Fixed ◐ items, as for any ◐ |
| Payday notice | `Payday — N transfers to make` counts the lines not All in; its other conditions are unchanged |
| Plan sorted by Account | the bank header already reads `AccountGroupState`; nothing changes |
| Paid early, set aside | lines and sheet rows use the Envelope's net amount, as today |
| Income lines | not linked; *has arrived* changes nothing here |
| Look back | unaffected |

## 8. Existing data

A line stored with `hasTransferred = true` was ticked Sent before this feature. The first time
the plan is maintained after the update, each such line sets every **Todo** item on it Funded,
then clears `hasTransferred`. Clearing it makes the step run once and sync once across
devices, with no flag of its own. In the sample BNI's and CC Danamon's items become ◐, so
both lines read **All in**, as they did. `[→ AD1]`

## 9. Unaffected

- The items' own checks and menus (§7.6), Done (§7.3), Auto posting (ADR-0007).
- Plan totals, Sisa, the share table, the drift strips.
- The adjustment editor `I2` itself; it is only reached from the sheet now.
- The line's plate, its name, its notes (`bank-logos.md` §5.6.4) in the Nothing-in and All-in states.

---

## 10. Decision log

Settled in a grilling session on 2026-10-24. The owner took every recommendation; there are no
owner overrides. Entries D1–D12 are defaults stated at the gate and confirmed with it; entries
12–21 are design calls made while drawing flow AD and approved at the design gate the same day.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Choose items per payday in a sheet per line; choosing records Funded — not items tied to an income, not a remaining-only caption | `AD2`–`AD4` |
| 2 | The line's tick is **derived** from its items: ◯ nothing in · ◐ part in · ✓ all in. Reverses `payday-planning.md` decision 25 | `AD1`, `AD4` |
| 3 | The adjustment lives **in the sheet**; the whole line is one tap target | `AD2` |
| 4 | The adjustment counts in the **first round** and is taken once any item is in; never below 0; derived, no new field | `AD6` |
| 5 | The sheet opens with **every Todo item chosen** | `AD2` |
| 6 | In items sit in **`ALREADY IN ‹Account›`**; ◐ has a `⋯` Menu `Not moved yet`; Done is read-only `paid` | `AD5`, `AD6` |
| 7 | Words follow Funded: **`Moved to ‹Account›`**; the header keeps `· N OF M SENT`, a part-in line is not sent; caption `1 item in · 2 to go` | `AD1`–`AD4` |
| 8 | A line stored as Sent sets its Todo items Funded **once** | `AD1` |
| 9 | No shortcut on ◯: always the sheet | `AD1` |
| 10 | Its own PRD, with pointers from `payday-planning.md` and `bank-logos.md` | — |
| 11 | `TO SEND` orders by **due day in cycle**, then amount ↓ | `AD2` |
| D1 | Amount: Nothing in and All in show Σ + adjustment; Part in shows Σ of the Todo items | `AD1` |
| D2 | A part-in caption's due days are the Todo items' only | `AD4` |
| D3 | §8 clears `hasTransferred` instead of keeping a per-device flag, so it syncs and runs once | — |
| D4 | Auto and Envelope items take part like any item; an all-Auto choice reads `Covered in ‹Account›`; Envelopes use their net amount | `AD7` |
| D5 | The button is disabled with nothing chosen | `AD3` |
| D6 | A choice lives only while the sheet is open | — |
| D7 | Lines keep their order; a state change does not move one | `AD4` |
| D8 | Carry-over unchanged: new plans start Nothing in; old plans keep their states | — |
| D9 | Notice priority unchanged; the funded notice appears after a partial round; the payday notice counts lines not All in | — |
| D10 | The Funded filter still hides the checklist; the plan filter (flow N) is ledger-only | — |
| D11 | The bank headers (sorted by Account) need no change | — |
| D12 | A part-in line's check is the existing `DoneCheck · Funded` glyph | `AD1` |
| 12 | The sheet closes with a ✕ glass button, not `Cancel`: with the plate, `Cancel` collided with `Transfer to Mandiri` | `AD2` |
| 13 | Choosing uses the existing `SelectionCircle`, as in flows Q/R; the section headers keep it apart from a ✓ Done | `AD2`, `AD3` |
| 14 | A `TO SEND` caption is Category · Auto · Due, no Person | `AD2`, `AD6` |
| 15 | An unchosen row stays in place and greys its amount | `AD3` |
| 16 | The figures card: Adjustment with chevron, red when negative, `Taken with the first transfer`; `Transfer now` bold accent; `Total` when all in | `AD2`, `AD6`, `AD7` |
| 17 | The button is a full-width `SavePill` under the figures | `AD2` |
| 18 | An in row's whole row is the Menu's label, `⋯` only marks it — against a separate ⋯ button, which squeezed long names | `AD5`, `AD7` |
| 19 | A Done row reads `‹Category› · paid` with its planned amount | `AD6` |
| 20 | `Not moved yet` carries `Back to To send` and an undo glyph | `AD5` |
| 21 | The flow is lettered AD, since flow AA's frames are AC1–AC4 | — |

`payday-planning.md` decision 25 and §7.6's "The transfer line's tick stays independent" are
superseded by entry 2; §6.1.4 and §7.5's "a checkbox" by §5.

---

## 11. Design traceability

Page `05 · Proposals — not built`, **Flow AD · Transferring part of a line**.

| Frame | Covers |
|---|---|
| **AD1** · Payday, salary in — the checklist | §5.1 states, §5.3 Mandiri, §8 BNI and CC Danamon, decisions 2, 7, 8, 9 |
| **AD2** · Transfer to BCA — opened | §6.1, §6.2 default and order, decisions 3, 5, 11 |
| **AD3** · Only Kos chosen | §6.2 total, §6.3 button, D5 |
| **AD4** · After `Moved to BCA` | §5.1 part in, D1, D2, D7 |
| **AD5** · BCA again — `Not moved yet` | §6.1 `ALREADY IN`, §6.3 Menu, decision 6 |
| **AD6** · Transfer to Mandiri | §5.3 adjustment taken, Done read-only |
| **AD7** · Transfer to BNI — all in | §6.1 all-in sheet, D4 |
