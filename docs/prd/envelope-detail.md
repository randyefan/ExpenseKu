# PRD — Envelope detail

Status: Accepted
Date: 2026-10-14 · grilled and design approved the same day (flow T)
Owner: Randy Efan

Companion documents: `docs/prd/envelope-assignment.md` (where an expense counts, §4.1;
＋ on the row, §4.5; Move expenses here…, §4.9; paying ahead, §4.10),
`docs/prd/payday-planning.md` (the Envelope, §5.1–5.2), `CONTEXT.md` (ubiquitous
language), `docs/adr/0005-plan-and-ledger-are-separate.md`,
`docs/adr/0008-envelope-assignment-overrides-category.md`,
`docs/adr/0009-assignment-may-pay-ahead.md`, and **`design/ExpenseKu.pen`**, page
`05 · Proposals — not built`, **Flow T**. Frame references appear inline as `[→ T2]`.

---

## 1. What this is

An Envelope row in the Plan lens says how much it has absorbed — a bar, a remainder, and
since flow S a caption "Rp 1.200.000 paid early in October" — but there is no way to see
**which expenses** make up that figure. Tapping the row opens the plan item editor, which
answers "what did I plan", not "where did it go". The ways around it all fall short:

- The List lens with **From plan only** mixes every envelope and every Fixed item; there
  is no per-envelope filter, on purpose (`envelope-assignment.md` §3).
- An expense **paid early** is dated in an earlier cycle, so the envelope's own List lens
  never lists it; only the caption says it exists.
- **Move expenses here…** lists exactly the expenses that are *not* in the envelope.

This feature makes tapping an Envelope row open its **detail**: the bar and remainder on
top, then every expense the envelope counts — by category, assigned, and paid early from
an earlier cycle.

## 2. Goals

1. Answer "which expenses make up this envelope's spent figure" in one tap from the row.
2. Show paid-early expenses beside the envelope's own, so the caption can be checked.
3. Agree with the bar to the rupiah: the list totals exactly `EnvelopeProgress.spent`.
4. Keep the envelope's actions — ＋ New expense, Move expenses here…, Edit — one tap away.

## 3. Non-goals

- **A second resolver.** Which expense counts where stays `EnvelopeClaims`' job
  (`envelope-assignment.md` §4.1). The detail asks it; it decides nothing.
- **A detail for Fixed items or dormant envelopes.** A Fixed row keeps opening its editor;
  a dormant row keeps its tap-to-wake (§4.1).
- **Telling assigned from by-category** in the list. Tags never did (`envelope-assignment.md`
  decision 15), and here there are none (§4.4).
- **Filtering or sorting the list.** The plan filter, the expense filter and the plan sort
  do not reach into the detail.
- **Restoring the detail after a relaunch.**
- **Schema changes.** None: everything shown is derived.

---

## 4. The rules

### 4.1 Entry

| Row in the Plan lens | Tap on its body |
|---|---|
| **Envelope, active** | opens the envelope's detail — *new* `[→ T1]` |
| Fixed (Auto included) | opens the plan item editor — unchanged |
| Dormant (in "From last cycle") | wakes it and opens the editor — unchanged |

- The body is everything but the lead glyph and ＋: name, amount, Account line, bar,
  legend and the paid-early caption. The caption is not a separate target; it opens the
  detail at its top, like the rest of the body (`envelope-assignment.md` §4.10.6 keeps
  its decision S).
- ＋ on the row is unchanged: its menu still offers New expense and Move expenses here….
- The same applies while the plan is filtered to Funded items (L6).
- VoiceOver keeps the row's label and adds the hint **"Shows its expenses"**.

*Amends* `envelope-assignment.md` §4.5 ("the row still opens the item editor") and
§4.10.6 ("a tap opens the item editor").

### 4.2 The sheet

A `.large` sheet with a grabber `[→ T2]`:

| Place | Shows |
|---|---|
| Leading toolbar | **✕**, labelled **Close** — the glass icon button |
| Title | the envelope's name, one line, truncated with "…", "Untitled" when empty |
| Subtitle | the cycle's title — **"October 2026"** |
| Trailing toolbar | **Edit**, a glass text button like Done and Cancel |

Under the toolbar, the card (§4.3), then the list (§4.4), or the empty state (§4.5).

### 4.3 The card

One card, the envelope row's own content restated, top to bottom `[→ T2, T3, T4]`:

| Line | Reads | When |
|---|---|---|
| Headline | the spent figure, **"Rp 685.000"**, large | always |
| Under it | **"spent of Rp 2.000.000"**, secondary | always |
| Account | `PlanChip` with the Account, and `FundedPlace` "in ‹account›" once Funded — as the row | the envelope has an Account |
| Bar | `EnvelopeBar`: spent left, "Rp X left" / "Rp X over" right — as the row | always |
| ＋ | the row's violet ＋ menu, level with the bar | always |
| Caption | `paidEarlyCaption`, exactly the row's text | paid-early expenses exist |
| Hairline, then claims | the claimed Categories by name, sorted, joined " · " — "Bensin · E-money · Makan" — or **"Assigned expenses only"** | always |

Every figure comes from the cycle's `EnvelopeProgress`, the same value that draws the row.
Over budget, the headline stays in primary text; the bar and remainder turn red as on
the row.

- The headline is large and bold (the editor's title size), "spent of …" caption-size
  secondary under it.
- The bar line and its legend are the row's: the legend stops short of the ＋ column, and
  ＋ sits level with the bar. An envelope at Rp 0 still draws the bar's 10pt minimum dot.
- The claims line is last, under a hairline, in secondary text. It never truncates the
  card: long names wrap.

### 4.4 The list

What is listed is decided by `EnvelopeClaims` for the envelope's cycle, and nothing else:

| Part | Expenses | Source |
|---|---|---|
| Own cycle | every expense dated in the envelope's cycle for which `envelope(for:)` returns this envelope | by category or assigned |
| Paid early | every expense `paidEarly(into:)` returns for this envelope | assigned from an earlier cycle |

- The two parts together total **exactly** `EnvelopeProgress.spent`. — unit test
- A Fixed item's expense, a **No envelope** expense, an expense assigned to another
  envelope, and one paid early into a *later* cycle never appear. — unit test

Layout `[→ T2, T3, T4]`:

1. **Own cycle first, unheaded**, grouped by day, newest day first, each day under a
   `DayGroupHeader` with its total — exactly the List lens.
2. **Then one section per earlier cycle** holding paid-early expenses, newest cycle first,
   headed **"Paid early · ‹cycle title›"** (drawn in capitals by `SectionHeaderText`, as in
   Move expenses here…), grouped by day the same way. The section header carries no total;
   the caption already does.
3. A part with nothing in it is not drawn. An envelope holding only paid-early expenses
   starts straight at the first "Paid early" header.

Rows are `ExpenseListRow` with **no envelope tag** — no outlined tag, no dashed paid-early
tag. Every row here counts in this envelope, so the tag would only repeat the title.

| On a row | Does |
|---|---|
| Tap | opens the expense editor (§4.6) |
| Long-press | **Move to envelope…** (when §4.8 of `envelope-assignment.md` offers it), **Edit**, **Delete** — no Select `[→ R1]` |
| Swipe left | Delete, at once |

A row that is deleted, or moved out, leaves the list at once and the card follows; the
sheet stays open.

### 4.5 Empty

With nothing in either part, the card stays (Rp 0, an empty bar, ＋) and the list is
replaced by a centred `EmptyStateView` under the `tray` glyph, in its default amber badge,
with a generous gap below the card `[→ T5, T6]`. A long envelope name wraps in the title:

| The envelope claims | Title | Message |
|---|---|---|
| one or more Categories | **"Nothing in ‹name› yet"** | **"‹Categories› expenses this cycle land here by themselves."** — the names sorted, joined as a list: "Bensin, E-money and Makan expenses…" |
| none | **"Nothing in ‹name› yet"** | **"Only expenses you assign land here. Use ＋ to add one or move some in."** |

### 4.6 Actions from the detail

Every action that opens another sheet **closes the detail first**, opens its sheet from
the Plan lens, and **reopens the detail** when that sheet closes. Two sheets are never
stacked.

| Action | Opens | Afterwards |
|---|---|---|
| **Edit** | the plan item editor | detail reopens — on Save and on Cancel |
| ＋ › **New expense** | Add Expense, assigned here, dated by `EnvelopeAddDate` (`envelope-assignment.md` §4.5) | detail reopens — saved or cancelled |
| ＋ › **Move expenses here…** | the gather sheet (`envelope-assignment.md` §4.9) | detail reopens |
| Tap a row | the expense editor | detail reopens |
| Long-press › **Move to envelope…** | the move sheet for that expense | detail reopens |
| Long-press › **Edit** | the expense editor | detail reopens |
| Long-press › **Delete**, swipe | — (in place) | detail stays open |

The detail reopens only while the envelope **still exists and is still active** in that
cycle's plan:

| When the other sheet closes, the envelope is… | Owner lands on |
|---|---|
| active | the detail, updated |
| deleted (Edit › Delete plan item › I7 confirmed) | the Plan lens |
| dormant (Edit set it to Rp 0 with nothing assigned) | the Plan lens |

Cancelling the I7 confirmation reopens the detail.

On iPad (regular width) a row's editor opens in the detail pane, not as a sheet; there
the detail closes and does not reopen.

---

## 5. Lifetime

The open detail is view state of `ExpensesView`, above the lens's `.id()`, never stored.

| Event | Detail afterwards |
|---|---|
| ✕, or swiping the sheet down | closed |
| Another sheet opened from it (§4.6) | closed, then reopened when that sheet closes |
| The envelope deleted while it is open (a sync) | closed |
| The envelope no longer active when a sheet closes | stays closed |
| An expense added, moved in, moved out or deleted | open, list and card updated |
| Paging, lens switch, tab switch, payday change | cannot happen: the sheet covers the navigator and the tab bar |
| App relaunched | closed |

Closing the detail leaves the Plan lens as it was: its scroll offset, sort, Funded filter
and dormant section untouched.

## 6. Unaffected

- **`EnvelopeClaims`, `EnvelopeSpend`, `PlanOrigins`** — read, never changed.
- **The envelope row** — its look, its ＋ menu, the caption.
- **Fixed rows and dormant rows** — their taps.
- **The List lens, Month, Search, Insights** — no new filter, no envelope dimension.
- **The schema** — no V5.
- **ADR-0005, ADR-0008, ADR-0009** — the plan is still not a ledger, an assignment still
  overrides the Category claim, and paid-early expenses are still counted once.

---

## 7. Sample data

Payday 25. Both samples come from existing seeds.

### 7.1 October 2026 · `-seedPlanData travelling`

October 2026 runs 25 Sep – 24 Oct.

| Expense | Date | Category | Choice | Counts in |
|---|---|---|---|---|
| (seed, no note) | 28 Sep | Makan Rp 420.000 | by category | Hidup |
| (seed, no note) | 28 Sep | Bensin Rp 191.400 | by category | Hidup |
| (seed, no note) | 28 Sep | E-money Rp 100.000 | by category | Hidup |
| Nasi Padang Bandung | 29 Sep | Makan Rp 85.000 | Travelling | Travelling |
| Bensin ke Bandung | 29 Sep | Bensin Rp 150.000 | Travelling | Travelling |
| Hotel Bandung | 29 Sep | Sewa Rp 450.000 | Travelling | Travelling |
| Kado ultah Tarisa | 29 Sep | Makan Rp 250.000 | No envelope | nothing |

- **Travelling** detail `[→ T2]`: Rp 685.000 spent of Rp 2.000.000, Rp 1.315.000 left,
  "Assigned expenses only"; one day, 29 Sep, Rp 685.000: Hotel, Bensin ke Bandung, Nasi
  Padang — untagged.
- **Hidup** detail `[→ T3]`: Rp 711.400 spent of Rp 938.300, Rp 226.900 left,
  "Bensin · E-money · Makan"; one day, 28 Sep, Rp 711.400: the three seed expenses. Nasi
  Padang and Bensin ke Bandung are **not** listed (assigned to Travelling), nor is the
  gift (No envelope).

### 7.2 November 2026 · `-seedPlanData paid-early`

November 2026 runs 25 Oct – 24 Nov; today is 14 Oct. November's plan was carried over
from October and gained Travelling (Rp 2.000.000, no Categories).

| Expense | Date | Category | Choice | Counts in |
|---|---|---|---|---|
| Tiket KAI ke Jakarta | 14 Oct | Transport Rp 1.200.000 | Travelling (November) | November's Travelling, paid early |

- **Travelling** detail, November `[→ T4]`: Rp 1.200.000 spent of Rp 2.000.000,
  Rp 800.000 left, caption "Rp 1.200.000 paid early in October", "Assigned expenses
  only"; no own-cycle part; **PAID EARLY · OCTOBER 2026**, 14 Oct, Rp 1.200.000: Tiket KAI
  ke Jakarta, untagged.
- **Hidup** detail, November `[→ T5]`: Rp 0 spent of Rp 938.300; "Nothing in Hidup
  (Makan, bensin, emoney saldo) yet" — "Bensin, E-money and Makan expenses this cycle land
  here by themselves."
- **Travelling** detail, November, before the ticket is assigned `[→ T6]`: Rp 0 of
  Rp 2.000.000; "Nothing in Travelling yet" — "Only expenses you assign land here. Use ＋
  to add one or move some in."

---

## 8. Decision log

Settled in a grilling session on 2026-10-14.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Tapping an active Envelope row opens its detail; the item editor moves behind **Edit** | `T1`, `T2` |
| 2 | The detail is a **`.large` sheet** closed with ✕ — *owner override*, against a push | `T2` |
| 3 | The list is by day like the List lens: own cycle unheaded, then one **"Paid early · ‹cycle title›"** section per earlier cycle | `T2`, `T4` |
| 4 | A card on top: spent headline, bar and legend, paid-early caption, claimed Categories or "Assigned expenses only", the Account chip when there is one | `T2`, `T3`, `T4` |
| 5 | The row's violet ＋ menu sits in the card level with the bar; **Edit** is a text button in the trailing toolbar | `T2` |
| 6 | Rows behave as everywhere: tap edits, long-press Move to envelope… / Edit / Delete (no Select), swipe deletes | `R1` |
| 7 | Rows carry **no envelope tag**, paid-early ones included | `T2`, `T4` |
| 8 | Empty: the card stays; "Nothing in ‹name› yet" with a message that depends on whether the envelope claims Categories | `T5`, `T6` |
| 9 | Only **active Envelopes** get a detail; Fixed and dormant rows keep their taps | `T1` |
| 10 | **Edit** closes the detail, opens the editor, and reopens the detail afterwards — *owner override*, against the editor over the detail | — simulator |
| 11 | The paid-early caption is part of the row; it opens the detail at its top, never scrolled | — |
| 12 | Words: title ‹name›, subtitle ‹cycle title›, "spent of Rp X", Close, Edit, "Paid early · ‹cycle title›", VoiceOver hint "Shows its expenses" | `T2` |
| 13 | Its own PRD; `envelope-assignment.md` §4.5 and §4.10.6 carry "amended by" notes; `CONTEXT.md` unchanged | — |
| 14 | ＋ New expense, Move expenses here…, a row's editor and Move to envelope… also close the detail and reopen it afterwards — *owner override*, against stacking them over it | — simulator |
| A | The list asks `EnvelopeClaims` only (`envelope(for:)`, `paidEarly(into:)`); its total equals `EnvelopeProgress.spent` | — unit test |
| B | Several earlier cycles: one section each, newest first; section headers carry no total | — unit test |
| C | The detail reopens after Save and Cancel alike, only while the envelope exists and is active | — simulator |
| D | Deleted while open (a sync): the detail closes | — |
| E | Never restored after relaunch; paging, lens and tab switches cannot happen while it is open | — |
| F | Plan filter, expense filter and plan sort do not apply; a Funded-filtered envelope row opens it too | — |
| G | Delete (long-press or swipe) acts in place and keeps the detail open | — simulator |
| H | Past and future cycles' envelopes get the same detail, ＋ included | — |
| I | iPad: a row's editor opens in the detail pane and the detail does not reopen | — |
| J | Sample data from the `travelling` and `paid-early` seeds; no new variant | — |
| K | No schema change, no new ADR | — |

Settled when the owner approved flow T on 2026-10-14:

| # | Decision | Drawn in |
|---|---|---|
| 15 | Headline large and bold, "spent of Rp X" caption-size secondary under it | `T2` |
| 16 | The card's bar, legend and ＋ are the row's own, ＋ level with the bar | `T2`, `T4` |
| 17 | The claims line sits last in the card, under a hairline | `T2`, `T3` |
| 18 | No Account chip is drawn (neither sample has one); §4.3's rule stands | — |
| 19 | An empty bar keeps `EnvelopeBar`'s 10pt minimum | `T5`, `T6` |
| 20 | Empty state is `EmptyStateView` with `tray` in its amber badge, not violet | `T5`, `T6` |
| 21 | A long title truncates with "…"; the empty title wraps | `T3`, `T5` |
| 22 | A "Paid early" header has a gap above it and no total | `T4` |
| 23 | Edit is a glass text button, like Done and Cancel | `T2` |
| 24 | The close-and-reopen of decisions 10 and 14 is not drawn; it is verified in the simulator | — |

---

## 9. Design traceability

Page `05 · Proposals — not built`, **Flow T · Envelope detail**, with the §7 samples.

| Frame | Covers |
|---|---|
| **T1** · Plan lens, November — tap Travelling (opens T4) | §4.1 entry |
| **T2** · Travelling detail, October | §4.2 sheet, §4.3 card, §4.4 list without tags |
| **T3** · Hidup detail, October | §4.3 claimed Categories, §4.4 assigned expenses left out |
| **T4** · Travelling detail, November — paid early | §4.3 caption, §4.4 Paid early section, no own part |
| **T5** · Hidup detail, November — empty | §4.5 claims Categories |
| **T6** · Travelling detail, November — empty | §4.5 assigned only |
