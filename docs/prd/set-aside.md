# PRD — Setting money aside for a later envelope

Status: Accepted — design approved 2026-10-17 (flow W)
Date: 2026-10-17
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the plan this adds a third kind of
item to), `docs/prd/envelope-assignment.md` §4.10 (Paid early, the mirror image of this),
`docs/prd/envelope-detail.md` (the sheet that lists it), ADR-0010, `CONTEXT.md`, and
**`design/ExpenseKu.pen`**, page `05 · Proposals — not built`, **Flow W**. Frame
references appear inline as `[→ W2]`.

---

## 1. What this is

The owner plans a trip to Japan in December and wants Rp 20.000.000 for it. Asking
December's payday for all of it is too heavy. In October, and again in November, there
is money left over, and the owner wants to put some of it towards Japan, then log every
expense in Japan as they do today.

Paid early (`envelope-assignment.md` §4.10) already moves money between plans, but only
behind an **expense**: the ticket bought in October counts in November's Travelling. Here
nothing has been bought yet. The owner moves **planned money**, not spending.

This feature adds a third kind of PlanItem, **Set aside**: a line in an earlier cycle's
plan that sends an amount to an envelope of a later cycle's plan. October's Sisa falls by
it because it is in October's Total cost. December's Sisa rises by it. The trip is still
logged and assigned to the "Jepang" envelope exactly as today.

## 2. Goals

1. Spread the cost of a future envelope over earlier cycles, in amounts the owner picks
   each time.
2. Keep both plans honest: the money is counted once, leaving one plan and arriving in
   the other.
3. Leave the ledger alone. Setting money aside is not spending, so no Expense is created
   and Insights never sees it (ADR-0005).
4. Fit the payday routine: the line can name an Account, joins that Account's transfer
   line, and can be ticked once the money has moved.

## 3. Non-goals

- **A savings goal or a balance.** The app does not track what sits in an account
  (CONTEXT.md). A set-aside line is an intention inside one plan, like every other line.
- **Spreading automatically.** The owner types each amount. Nothing divides Rp 20.000.000
  into months.
- **Copying forward.** Carry-over never copies a set-aside line (§4.8, *owner override*).
- **Setting aside into a Fixed item or into an earlier cycle.** The target is always an
  envelope of a later cycle.
- **Creating a plan to have a target.** Only plans that already exist are offered.
- **A second entry point.** The envelope's ＋ menu does not gain "Set aside from…".

---

## 4. The rules

### 4.1 The kind

`PlanItemKind` gains `.setAside`. A set-aside item has:

| Field | Set aside |
|---|---|
| Amount | yes, as any item |
| **For** (target envelope) | an envelope of a later cycle's plan; required to save |
| Account | optional |
| Category, People, due day, Auto | none |
| Name | none of its own — the row reads the envelope's name |

It counts in its own plan's **Total cost** like any active item, so its own cycle's Sisa
falls by it with no reconciling row. `[→ W1]`

### 4.2 The editor

The kind segment becomes **Fixed | Envelope | Set aside**. With Set aside chosen, the form
shows Amount, **For** and Account. `[→ W3]`

- **For** opens a picker of envelopes, one section per later cycle that has a plan and
  has not ended, oldest first, headed with the cycle title ("DECEMBER 2026"), envelopes
  by planned amount ↓, then name, each with its planned amount. This is the list
  `EnvelopeOffer` already builds for paid early, without its own-cycle section and
  without By category / No envelope. `[→ W4]`
- The chosen target reads **"Jepang · Dec"**: the name in primary text, "· ‹Mon›" in
  secondary, the name truncating and never the suffix, as with paid early's editor row.
- With no later envelope on offer, the For row reads **"No envelope in a later plan"** in
  secondary text with a footnote: "Page forward to a later cycle and add an envelope
  first." Save is disabled. The segment is still offered. `[→ W10]`
- Save is disabled until a target is chosen and the amount is above 0.
- An existing set-aside item can be re-pointed at any time; its kind can be changed like
  any other item's (choosing Fixed or Envelope drops the target).

### 4.3 The row

A set-aside row sits in the plan list with the other items and follows the active sort.
`[→ W1]`

```
◯  → Jepang · Dec                     5.000.000
     Set aside · Jago
```

- **Title**: a violet `arrow.forward` glyph, the envelope's name, then "· ‹Mon›" in
  secondary — the paid-early tag's month rule (`envelope-assignment.md` §4.10.5): ‹Mon› is
  the three-letter month of the target cycle's title, with the year when 12 or more
  cycles ahead.
- **Second line**: "Set aside" in caption-size secondary text, then the Account chip when there is one.
- **Leading check**: two states (§4.4).
- A tap on the row opens the item editor, as for every other row.
- VoiceOver: **"Set aside for Jepang, December, Rp 5.000.000, not moved"** / "…, moved".

### 4.4 Ticking it

Two states: **◯ not moved** and **✓ moved**. No Funded ◐, no confirmation sheet, and no
Expense. The check is a menu of one item, like the Auto bolt, so a stray tap while
scrolling does nothing. `[→ W2]`

| Now | Account | Menu item | Then |
|---|---|---|---|
| ◯ | Jago | **Moved to Jago** | ✓ |
| ◯ | none | **Set aside** | ✓ |
| ✓ | Jago | **Not moved yet** | ◯ |
| ✓ | none | **Not set aside yet** | ◯ |

- ✓ draws the Done face; the row is otherwise unchanged.
- The state never changes any figure (§4.5). It is a fact the owner reports, like a
  transfer tick.
- In the **Status** sort, ◯ is Todo and ✓ is Done.
- The funded notice and the Funded filter ignore set-aside items.

### 4.5 Money between the two plans

The amount leaves its own plan and arrives in the target envelope's plan, **from the
moment the line exists**, ticked or not.

| | Its own cycle (October) | The target's cycle (December) |
|---|---|---|
| Total cost | includes it | unchanged — the envelope's planned amount |
| Reconciling row | none | **"Set aside in October"**, positive `[→ W5]` |
| Sisa | `income − cost …` (it is in cost) | `… + set aside in` |
| Transfer line | adds to its Account's line (ke Jago +5.000.000) | the envelope's contribution is net (§4.6) |
| Group shares | counts in the target envelope's Group | the envelope counts net (§4.6) |

`Sisa = Total income − Total cost − paid early out + paid early in + set aside in`.

- **No cap** — *owner override*. Rp 25.000.000 set aside into a Rp 20.000.000 Jepang
  credits December Rp 25.000.000; the extra Rp 5.000.000 becomes free money in December's
  Sisa. Paid early keeps its own cap (`envelope-assignment.md` §4.10.10), computed as
  before and unaffected by set-aside lines.
- **Ticked or not, it counts.** Sisa is intention, never balance.
- The December credit is the Σ of the amounts of every set-aside item targeting one of
  that plan's envelopes, whichever earlier plans hold them.
- A set-aside item whose target is missing or no longer later (§4.9) still counts in its
  own Total cost and credits nothing.

**The reconciling row** sits on December's totals card under Total cost, below a
Paid early row when both show, in the Paid early row's style: violet `arrow.forward`, the
label and amount styled as Total cost, a **+**, no green. Not tappable.

| Set-aside items come from | Label |
|---|---|
| one earlier cycle | **Set aside in October** — that cycle's title month, wide |
| several | **Set aside earlier** |
| none | no row |

### 4.6 The target envelope's cycle

The envelope row keeps its planned amount, its bar of what is spent and its legend
("Rp 6.500.000 · Rp 13.500.000 left"), and adds **one** line under the legend for every
rupiah that reached it from earlier cycles, paid early and set aside together: `[→ W5]`

```
→ Rp 18.500.000 from earlier
```

| Money from earlier cycles (paid early + set aside) comes from | Line |
|---|---|
| one earlier cycle | **"→ Rp 5.000.000 from October"** — that cycle's title month, wide |
| several | **"→ Rp 18.500.000 from earlier"** |
| none | no line |

- The figure is Σ of the paid-early expenses counting in the envelope **plus** Σ of the
  set-aside lines targeting it. It is not capped: it says what arrived, not what was
  credited.
- A violet `arrow.forward` glyph leads it; the text is caption size, secondary.
- **This replaces the paid-early caption** of `envelope-assignment.md` §4.10.6 for every
  envelope, set-aside money or not — *owner choice* after the first draft (two captions)
  read as too busy. "Rp 1.200.000 paid early in October" becomes
  "→ Rp 1.200.000 from October".
- The split is in the envelope detail (§4.7), never on the row.
- **This cycle's share** sits under the planned amount, right-aligned, caption size,
  secondary: **"Rp 1.500.000 from December"** — `max(0, planned − paid-early credit −
  set aside in)`, the envelope's own cycle's title month, wide. It is the same figure the
  envelope adds to its Account's transfer line, and it is drawn only when the
  from-earlier line is. Fully covered, it reads "Rp 0 from December". The planned amount
  above it is unchanged, so the row still shows what Total cost adds up. `[→ W5]`
- The envelope detail's card carries the same line. `[→ W9]`

**Net figures.** The envelope's contribution to its Account's transfer line, and to its
Group's share, is `max(0, planned − paid-early credit − set aside in)`. `[→ W6]`

- The transfer row's second line names it, in the adjustment line's place:
  **"Rp 12.000.000 set aside into Jepang"**; several envelopes on one account read
  **"Rp X set aside"**. With paid early or a manual adjustment too, every part shares the
  line, adjustment first, then paid early, then set aside, joined by " · ".
- The Account the set-aside line named in October is not compared with the envelope's
  Account. The app knows no balances.
- Drift is unchanged: overspend is spent minus planned, whatever was set aside.

### 4.7 Envelope detail

The detail sheet (`envelope-detail.md`) gains a **SET ASIDE** section after the expense
list: one row per set-aside item targeting the envelope, oldest cycle first, reading
"‹Cycle title›", then "‹Account› · moved" or "‹Account› · not moved yet", its ◯/✓ face, and
the amount. Read only — the line belongs to another cycle's plan, so the check is not a
control here. Not drawn when there is none. `[→ W9]`

### 4.8 Carry-over

A new cycle's plan **never copies** set-aside items — *owner override*. Each cycle the
owner adds the line again if there is money to spare. A set-aside item is never dormant.

### 4.9 Losing the target

| What happens | The set-aside item |
|---|---|
| The target envelope is deleted | kept, target nil (ADR-0001) |
| The target is changed to Fixed or Set aside | kept, target ignored |
| A payday change re-cuts cycles so the target is no longer later | kept, target ignored |
| Its own plan's cycle ends | unchanged — still reads "Jepang · Dec" |

A kept item with no valid target still counts in its own Total cost and credits nothing.
Its title reads **"No envelope"** and its second line shows a warning-coloured
**"Pick an envelope"**, with a warning glyph before the title; a tap opens the editor
with For empty. `[→ W8]`

Deleting an envelope that set-aside items target adds a sentence to the existing
confirmation (`envelope-assignment.md` §4.7), after the assigned-expenses one:
**"2 set-asides in October and November will lose their envelope."** (one: "1 set-aside
in October will lose its envelope."). `[→ W7]`

---

## 5. Lifetime

Nothing here is view state. Every figure is derived per read from the stored target; the
only stored facts are the item, its target and its moved flag.

| Event | Effect |
|---|---|
| Line added, amount edited, line deleted | both plans' Sisa move at once |
| Tick or untick | no figure moves |
| Target envelope deleted | §4.9 |
| New cycle (carry-over) | not copied |
| Relaunch, paging, lens switch | nothing to keep |

## 6. Unaffected

- **The ledger**: List, Month, Search, cycle totals, Insights, the List header split,
  the plan filter and the expense filter. No Expense is created.
- **Paid early**: its cap and tags. Its envelope caption is replaced (§4.6, decision 15).
- **Envelope bars and drift.** A bar is spending; setting aside is not.
- **The funded notice**, the Funded filter and the review notice.
- **Dormancy** — a set-aside item is never dormant.

---

## 7. Sample data

Payday 25, today 17 Oct 2026. Reused in every frame and in the tests.

**October 2026** (25 Sep – 24 Oct)

| Line | Kind | Amount | Account |
|---|---|---|---|
| Gaji | income | 18.000.000 | |
| Kos | Fixed | 2.200.000 | BCA |
| Hidup (Makan, Transport) | Envelope | 3.000.000 | |
| → Jepang · Dec | Set aside, ✓ | 5.000.000 | Jago |
| Tiket Jakarta–Tokyo, 2 Oct | Expense, paid early into Jepang | 6.500.000 | |

Total cost 10.200.000 · Paid early for December −6.500.000 · **Sisa 1.300.000** ·
ke Jago 5.000.000.

**November 2026** (25 Oct – 24 Nov)

| Line | Kind | Amount | Account |
|---|---|---|---|
| Gaji | income | 18.000.000 | |
| Kos | Fixed | 2.200.000 | BCA |
| Hidup | Envelope | 3.000.000 | |
| → Jepang · Dec | Set aside, ◯ | 7.000.000 | Jago |

Total cost 12.200.000 · **Sisa 5.800.000** · ke Jago 7.000.000.

**December 2026** (25 Nov – 24 Dec)

| Line | Kind | Amount | Account |
|---|---|---|---|
| Gaji | income | 18.000.000 | |
| Kos | Fixed | 2.200.000 | BCA |
| Hidup | Envelope | 3.000.000 | |
| Jepang (no categories) | Envelope | 20.000.000 | Jago |

Total cost 25.200.000 · Paid early in October +6.500.000 · Set aside earlier
+12.000.000 · **Sisa 11.300.000**. Jepang: "Rp 6.500.000 · Rp 13.500.000 left" (the ticket
is spent in it), "→ Rp 18.500.000 from earlier", and under Rp 20.000.000
"Rp 1.500.000 from December". ke Jago 1.500.000,
"Rp 6.500.000 paid early · Rp 12.000.000 set aside".

**Uncapped variant**: November sets aside 16.000.000. December's credit is 21.000.000
(Set aside earlier) + 6.500.000 (Paid early); Sisa 20.300.000; ke Jago Rp 0.

---

## 8. Decision log

Settled in a grilling session on 2026-10-17. Entries 14–16 were settled at the design review the same day, when the owner approved flow W.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Money is **set aside** from an earlier plan into a later envelope; no Expense, the ledger untouched | `W1`, `W5` |
| 2 | It is **a plan row of its own**, a third PlanItem kind, not only a reconciling row | `W1` |
| 3 | Its check has **two states**, ◯ → ✓, through a one-item menu; no sheet | `W2` |
| 4 | The later plan is credited **from the planned amount**, ticked or not | `W5` |
| 5 | The later envelope shows it as a **caption under the bar**; the bar stays spending | `W5` |
| 6 | The credit is **not capped** at the envelope's planned amount — *owner override*, against capping it with paid early | `W5` |
| 7 | The later transfer line and Group share count the envelope **net, floored at 0** | `W6` |
| 8 | Created from the **item editor's third segment** only | `W3`, `W4` |
| 9 | Carry-over **never copies** it — *owner override*, against copying while the target is still later | — an absence |
| 10 | A deleted target **keeps the line**, warned, still debiting its own plan | `W7`, `W8` |
| 11 | The words are **Set aside** | `W1`–`W10` |
| 12 | In its own plan's Group shares it counts in the **target envelope's Group** | `W6` |
| 13 | Its own PRD and ADR-0010 | — |
| 14 | The envelope row shows **one line**, "→ Rp X from earlier / from ‹Month›", for paid early and set aside together — chosen at the design review over two captions (B: "…earlier · Rp X in December", C: the figure in the legend, D: two captions), which the owner found too busy | `W5`, `W9` |
| 15 | That line **replaces flow S's paid-early caption** on every envelope | `W5` |
| 16 | Under the planned amount, the row says **what this cycle still puts in** ("Rp 1.500.000 from December") — asked for by the owner at the design review; chosen over the figure on the caption line (A, B, too tight beside ＋) and leading with the share (D, hides the planned amount) | `W5` |

Defaults chosen without asking and confirmed at the gate:

| # | Default | Drawn in |
|---|---|---|
| D1 | Targets: active envelopes of later, existing, unended plans, by cycle — paid early's list | `W4` |
| D2 | No later envelope: For reads "No envelope in a later plan", Save disabled | `W10` |
| D3 | No name field; the row reads "‹envelope› · ‹Mon›" with a violet `arrow.forward` | `W1` |
| D4 | Account optional; with one it joins its transfer line and the menu says "Moved to ‹Account›" | `W1`, `W2` |
| D5 | No due day, Auto, Funded or dormancy; Status sort puts ◯ in Todo and ✓ in Done | — |
| D6 | One reconciling row on the later plan, "Set aside in ‹Month›" / "Set aside earlier", under Paid early | `W5` |
| D7 | ~~Both captions show, paid early first~~ — superseded by decision 14 | — |
| D8 | Paid early's cap is unchanged and ignores set-aside lines | — unit test |
| D9 | Envelope detail lists the lines in a read-only SET ASIDE section | `W9` |
| D10 | A target re-cut into the same or an earlier cycle is treated as missing | `W8`, unit test |
| D11 | Schema V5: `PlanItem.setAsideTarget` with its inverse on the envelope | — |
| D12 | The ledger, filters and notices are unaffected | — |

---

## 9. Design traceability

Page `05 · Proposals — not built`, **Flow W · Set aside**.

| Frame | Covers |
|---|---|
| **W1** · October plan with a set-aside line | §4.1, §4.3, transfer ke Jago |
| **W2** · The check's menu | §4.4 |
| **W3** · Editor, Set aside segment | §4.2 |
| **W4** · The For picker | §4.2, D1 |
| **W5** · December plan: Jepang and the totals card | §4.5, §4.6 captions |
| **W6** · December transfers and Group shares | §4.6 net figures |
| **W7** · Deleting Jepang: the confirmation names the set-asides | §4.9 |
| **W8** · October after the delete: the warned row | §4.9 |
| **W9** · Envelope detail, SET ASIDE section | §4.7 |
| **W10** · Editor with no later envelope | §4.2 empty case |
