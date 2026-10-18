# PRD — Looking back at an earlier cycle

Status: Built
Date: 2026-10-18 · design approved and built the same day (flow AB)
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Plan lens and carry-over this
extends), `docs/prd/envelope-assignment.md` and `docs/prd/set-aside.md` (paid early and
set-aside, both excluded here), `CONTEXT.md` (ubiquitous language), and
**`design/ExpenseKu.pen`**, page `02 · Pages · iPhone`, **Flow AB** (moved there from `05 · Proposals` once built). Frame
references appear inline as `[→ AB2]`.

---

## 1. What this is

Carry-over copies the previous plan **once**, the moment the owner first opens the new
cycle's plan (`payday-planning.md` §7.2). Everything that happens after that copy is
invisible from the new plan:

- an item added to October's plan *after* November's was created (paging forward in
  mid-October to start planning is exactly when this happens);
- an item the owner deleted from November's copy and now wants back;
- a dormant row in November that October went on to use;
- spending in October that **no plan covered** — Outside plan — which may be a cost that
  belongs in November's plan.

Today the owner's only way to see any of it is to page back with `‹`, lose the plan they
were editing, remember, page forward and type it again.

This feature adds **Look back**: a sheet, opened from the foot of a plan, that lists what
an earlier cycle had and this plan does not, and adds any of it with one tap.

## 2. Goals

1. While building a plan, see what the previous cycle **planned** that this plan lacks.
2. See what the previous cycle **spent outside its plan**, by Category.
3. Bring either into this plan in one tap, without leaving the plan.
4. Reach further back than one cycle when a cost does not recur monthly.

## 3. Non-goals

- **Re-running carry-over.** Nothing is copied unless the owner taps it.
- **Comparing amounts.** An item already in this plan is not listed because its amount
  differs; the editor's "was Rp … in August" hint already answers that.
- **Suggestions or prediction.** The sheet lists what happened; it never guesses.
- **Set-aside lines.** Never listed, as carry-over never copies them (`set-aside.md` §4.8).
- **Editing the earlier plan** from the sheet. It is read-only apart from what it adds here.
- **Income lines.** Carry-over already copies them all and they rarely change.

---

## 4. The entry row

A row **`Look back at October`**, naming the cycle before the one on screen by the
month it ends in, sits in the add-rows section at the foot of the plan, after
`Add income line`, in the same card and the same `PickerAddRow` style (accent text, glyph
in a track circle) with a `clock.arrow.circlepath` glyph and a trailing chevron, since it
opens a sheet (`LookBackEntryRow`). `[→ AB1]`

| Condition | Row |
|---|---|
| This cycle has a plan and an earlier cycle exists (a plan or an expense before it) | shown |
| No plan yet (`PlanEmptyState`) | not shown |
| No earlier cycle | not shown |
| Plan filtered to Funded (L6) | steps aside with the add rows |

The Plan sort and the Expense filter do not affect it.

## 5. The sheet

A `.large` sheet with the app's `presentationBackground(Theme.bg)`. `[→ AB2]`

- **Title bar** — `‹  October  ›` centred, the arrows small glass buttons, **Done**
  trailing; no ✕. An arrow that cannot move is dimmed and disabled.
- **Lead line** — "What November's plan doesn't have", naming the plan on screen, as the
  first line of the content (it is too wide for the title bar).
- Two sections, in this order: **In October's plan, not here** (§5.1) and **Outside plan
  in October** (§5.2). A section with no rows is not drawn.
- Both empty: `EmptyStateView` with a checkmark, the title **"Nothing to bring over"** and
  the message **"Nothing in October that November's plan doesn't have."** `[→ AB6]`

### 5.1 In October's plan, not here

Every PlanItem of the reviewed cycle's plan, except set-aside lines, that has **no item
of the same kind with the same normalised name** (`NameKey.normalized`) in this plan —
in any state, dormant included. Kind is Fixed or Envelope: "Hiburan" as a Fixed item in
October and "Hiburan" as an Envelope here are different items, so October's is listed.

| October's row | In this plan | Listed as | Action |
|---|---|---|---|
| in use (amount > 0, or done) | absent | normal row | **+** |
| in use | present, **dormant** | row with caption "dormant here" | **Wake** |
| in use | present, not dormant | — not listed | — |
| unused (Rp 0, never done) | absent | **dimmed** row | **+** |
| unused | present | — not listed | — |
| set-aside line | — | — never listed | — |

`[→ AB2]`

**Row content** (`LookBackRow`). A 26pt kind glyph leads, as on `DormantRow`: Fixed is
an outlined circle in tertiary grey, Envelope a tray in the plan violet. Then the name,
then October's **planned** amount — "Rp 400.000 · envelope" for an Envelope — then a small
caption when one applies:

- a done Fixed item whose actual differs: **"paid Rp 475.000 in October"**;
- a dormant match: **"dormant here"**;
- an Envelope whose categories are partly claimed here: **"Makan stays in Hidup"** (§6.3).

**Order.** Amount descending, then name, then creation — the plan's default order.
Wake rows sit where their amount puts them. Dimmed Rp 0 rows come last, by name; a dimmed
row's name, amount and glyph are dimmed, its action is not.

### 5.2 Outside plan in October

The reviewed cycle's **Outside plan** spending, judged by *its own* plan exactly as the
List lens split does (`PlanOrigins`), with one exclusion: **paid early** expenses —
assigned to an envelope of a later plan — are left out, because that money is already
planned. When any were left out, the header carries a second line,
**"excluding Rp 1.200.000 paid early"**, so the section total still reconciles with the
List lens. An expense assigned **No envelope** is Outside plan and is included.

Header: **`OUTSIDE PLAN IN OCTOBER · Rp 1.085.000`**.

One row per Category: its 44pt `CategoryIcon` and name, then "Rp 620.000 · 3 expenses".
Order: total descending, then name. `[→ AB2]`

| Category in this plan | Row | Action |
|---|---|---|
| claimed by no envelope, used by no Fixed item | normal | **+** menu (§6.2) |
| claimed by no envelope, used by a Fixed item here | caption **"Kos uses Sewa here"** | **+** menu |
| claimed by an envelope here | caption **"in Kebutuhan Kos di Jkt here"**, no + | — |
| Uncategorized | caption **"categorise them first"**, no + | — |

A Fixed item claims no Category, so its Category can still be Outside plan — a rent paid by
hand rather than through Done. The row keeps its + and names the Fixed item, so the owner
does not plan the same cost twice. More than one: "Netflix and 2 more use Hiburan here",
the first by the plan's default order. An envelope claim wins over a Fixed use. `[→ AB5]`

Uncategorized sorts by its total like any other row.

If the reviewed cycle had **no plan**, every expense of it is Outside plan, and §5.1 is
replaced by one line, **"October had no plan."** `[→ AB5]`

## 6. Adding

Every addition is written to this plan at once; there is no Save. A row that has been
acted on shows **✓ Added** (or **✓ Woken**) in the positive green, on a surface pill, in
place of its action, and its caption becomes a green line naming what happened:
"added to November", "woken in November", "new envelope in November", "new fixed item in
November", "added to Hidup". `[→ AB4]`

The actions are pills: **+ Add** in the accent wash (`DormantRow`'s Activate), **+ Add ▾**
where it opens a menu, **Wake** with a sun glyph.

### 6.1 + on a plan item

Copies the item into this plan exactly as carry-over copies it (`PlanCarryOver`):
name, planned amount, kind, Category, Account, People, due day, Auto and envelope
categories; clear of done, Funded and every progress fact. It is **not** marked
carried-over, so a copied Rp 0 row is an ordinary row, not dormant. The copy arrives
in the plan in its sort position, with no badge marking it new. `[→ AB7]`

### 6.2 + on an Outside plan category

Opens a menu titled "Kesehatan · Rp 620.000 in October". `[→ AB3]`

| Entry | Effect |
|---|---|
| **New envelope · Rp 620.000** | an Envelope named after the Category, its categories `{Kesehatan}`, amount = the row's total, no Account |
| **New fixed item · Rp 620.000** | a Fixed item named after the Category, that Category, amount = the row's total, no Account |
| **Add to Hidup**, one per envelope in this plan, in a section "Add to an envelope", by the plan's default order | adds the Category to that envelope; its amount is unchanged |

With no envelope in this plan, the section is not drawn.

### 6.3 Envelope categories already claimed

A Category belongs to at most one Envelope per plan. Copying an Envelope (§6.1) skips
any of its categories already claimed by an envelope here, and the row says so before
the tap: **"Makan stays in Hidup"**. Nothing moves out of an existing envelope.
An Envelope all of whose categories are claimed is still copied, with none.

### 6.4 Wake

Gives the dormant row here October's planned amount, which makes it active
(`PlanDormancy`). Nothing else on it changes.

### 6.5 Undo

While the sheet is open, tapping **Added ✓** or **Woken ✓** undoes it: the copy or new
item is deleted, the category leaves the envelope, the woken row returns to Rp 0. The
row returns to its action. Nothing done here can have an Expense yet, so undo never
touches the ledger. Once the sheet closes, the plan's own delete is the way back.

## 7. Paging

`‹` moves to the cycle before; `›` moves forward, stopping at the cycle **just before the
one on screen**. `‹` stops at the oldest cycle holding a plan or an expense
(`CyclePaging`'s own lower bound). The subtitle keeps naming the plan on screen.
`[→ AB5]`

Every rule in §5 is applied between the **reviewed** cycle and the plan **on screen**,
whichever cycle is reviewed.

## 8. Lifetime

| Event | Afterwards |
|---|---|
| Opening the sheet | reviews the cycle just before the one on screen |
| `‹ ›` inside the sheet | the Added/Woken marks of every page visited are kept until the sheet closes |
| Closing the sheet (Done or swipe) | marks are dropped; reopening lists only what is still missing, so an added item no longer appears |
| Paging the plan, switching lens, relaunch | the sheet is closed; nothing is remembered |

The sheet's state lives in `ExpensesView`, above the lens's `.id()`.

## 9. Unaffected

- **Carry-over** — unchanged; still a one-time copy.
- **Dormant section, sort, Funded filter, notices, totals** — unchanged. Sisa moves only
  because the plan gained items, as it would from the editor.
- **The reviewed cycle's plan and ledger** — read only.
- **The List lens split and Insights** — unchanged; this reads `PlanOrigins`, it does not
  alter it.

---

## 10. Decision log

Settled in a grilling session on 2026-10-18. Entries 28–37 were settled when the owner
approved flow AB the same day.

| # | Decision | Drawn in |
|---|---|---|
| 1 | A sheet opened from a row at the foot of the plan, not an inline section or a read-only peek | `AB1`, `AB2` |
| 2 | Opens on the previous cycle and pages back with `‹ ›` — *owner override*, against the previous cycle only | `AB2`, `AB5` |
| 3 | "Already here" means same normalised name **and** same kind — *owner override*, against name only | `AB2` |
| 4 | Unused (Rp 0, never done) rows are listed, dimmed, last — *owner override*, against hiding them | `AB2` |
| 5 | A match that is dormant here is listed with **Wake** — *owner override*, against counting it as present | `AB2`, `AB4` |
| 6 | + on a plan item copies it at once, as carry-over does, and the row reads Added ✓ | `AB4` |
| 7 | Copying an Envelope skips categories claimed here and says "Makan stays in Hidup" | `AB2` |
| 8 | Tapping Added ✓ undoes it while the sheet is open | `AB4` |
| 9 | Outside plan spending is grouped by Category: count and total, largest first | `AB2` |
| 10 | + on a category opens a menu: New envelope, New fixed item, Add to each envelope | `AB3` |
| 11 | A category claimed by an envelope here is still listed, "in Hidup here", without + | `AB2` |
| 12 | Plan rows order by amount descending, Wake rows in place, Rp 0 rows last | `AB2` |
| 13 | The **planned** amount is copied; "paid Rp X in October" shows when the actual differed | `AB2` |
| 14 | Words: "Look back at October", title `‹ October ›`, subtitle "What November's plan doesn't have" | `AB1`, `AB2` |
| 15 | Its own PRD, with a pointer from `payday-planning.md` §7.2 | — |
| 16 | Paid early expenses are excluded, with "excluding Rp X paid early" under the header | `AB2` |
| 17 | *Default:* set-aside lines are never listed | — an absence |
| 18 | *Default:* Wake gives the dormant row the reviewed cycle's planned amount; undo returns it to Rp 0 | `AB4` |
| 19 | *Default:* the sheet always opens on the previous cycle; `›` stops before the cycle on screen, `‹` at the oldest | `AB5` |
| 20 | *Default:* Added/Woken marks live while the sheet is open | — |
| 21 | *Default:* the entry row needs a plan and an earlier cycle, and steps aside under the Funded filter | `AB1` |
| 22 | *Default:* a reviewed cycle with no plan says "October had no plan" | `AB5` |
| 23 | *Default:* both sections empty → "Nothing in October that November's plan doesn't have."; an empty section is not drawn | `AB6` |
| 24 | *Default:* Uncategorized is a row without +, "categorise them first" | `AB2` |
| 25 | *Default:* a new item from a category is named after it, takes the row's total, no Account | `AB4` |
| 26 | *Default:* No envelope expenses count as Outside plan | — |
| 27 | *Default:* works for a plan of any cycle, past or future | — |
| 28 | *Design:* `‹ October ›` centred with Done trailing; the lead line carries "What November's plan doesn't have" | `AB2` |
| 29 | *Design:* plan rows lead with a 26pt kind glyph (◯ grey Fixed, violet tray Envelope); Outside rows with the 44pt CategoryIcon | `AB2` |
| 30 | *Design:* pills — + Add, + Add ▾ for a menu, Wake (sun), ✓ Added / ✓ Woken in green | `AB2`, `AB4` |
| 31 | *Design:* after an action the caption turns into a green line saying what happened | `AB4` |
| 32 | *Design:* the category menu is titled with the row and groups the envelopes under "Add to an envelope" | `AB3` |
| 33 | *Design:* a Category used by a Fixed item here keeps its + and says "Kos uses Sewa here" | `AB5` |
| 34 | *Design:* the empty sheet is EmptyStateView "Nothing to bring over" | `AB6` |
| 35 | *Design:* the entry row is a PickerAddRow-style row with clock.arrow.circlepath and a chevron | `AB1` |
| 36 | *Design:* added items carry no "new" badge in the plan | `AB7` |
| 37 | *Design:* a dimmed Rp 0 row keeps a full-colour action | `AB2` |

---

## 11. Design traceability

Page `02 · Pages · iPhone`, **Flow AB · Look back at an earlier cycle**. Components
`LookBackEntryRow`, `LookBackPlanRowView`, `LookBackCategoryRowView` and `LookBackActionPill` live on
`01 · Design System`, group `Cycle plan`, row `Look back`. One sample throughout: the
owner is building **November 2026**'s plan, which was copied from October on 12 October.
After that, October gained **Service motor** (Rp 450.000, paid Rp 475.000), **Jajan**
(envelope Rp 400.000, {Kopi, Makan}) and an amount on **Beli kado** (Rp 300.000; Rp 0 and
dormant in November); **Perpanjang STNK** (Rp 0) was deleted from November. October's
Outside plan: Kesehatan 3 × Rp 620.000, Hadiah 1 × Rp 250.000, Galon 2 × Rp 140.000
(November's Kebutuhan Kos di Jkt now claims Galon), Uncategorized 1 × Rp 75.000 —
Rp 1.085.000 — plus the paid-early Tiket KAI Rp 1.200.000 for November's Travelling.

| Frame | Covers |
|---|---|
| **AB1** · The plan's foot — Look back at October | §4 |
| **AB2** · The sheet — October | §5, §5.1 every row case, §5.2, §6.3 caption, decisions 3–5, 7, 9, 11–14, 16, 24 |
| **AB3** · + on Kesehatan — the menu | §6.2 |
| **AB4** · After four taps — Added ✓ / Woken ✓ | §6.1, §6.4, §6.5 |
| **AB5** · Paged back to August — no plan, ‹ at the oldest | §5.2 no-plan case and Fixed use, §7 |
| **AB6** · Nothing missing | §5 empty state |
| **AB7** · Back in November's plan | §6.1 copies in sort position, Sisa moved |

### 11.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| A tap writes at once, so a fresh derivation dropped the row just tapped, and its ✓ with it | The first derivation of each reviewed cycle is kept for the visit; a marked row stays as it was, every other row follows the live derivation (so "in Hidup here" appears as soon as Hidup takes the Category) | `LookBackDisplay`, `LookBackSheet` |
| Marks keyed by row alone would carry one cycle's ✓ to the same Category in another | Marks and snapshots are kept per reviewed cycle | `LookBackSheet` |
| A source used in its cycle at Rp 0 (done at Rp 0) whose match here is dormant | Not listed: Wake would leave the row at Rp 0, still dormant | `LookBack.planRows` |
| Which envelopes "claim here" | Every envelope of the plan, dormant ones included — the same map the editor uses to keep a Category in one envelope | `EnvelopeSpend.claims` |
| Paging back past January read as the coming one | The title carries the year when the reviewed cycle's year differs from the plan on screen's ("December 2025") | `LookBackCopy.title` |
| A Label with two Texts inside a menu Button dropped the subtitle | Title, subtitle and icon go straight into the Button's label | `LookBackCategoryRowView` |
| The sheet's list sat a full inset below the title bar | It uses the Plan lens's own list chrome (`cycleLensList`) | `LookBackSheet` |
| Outside plan rows draw the 44pt icon | 38pt, `Metric.rowIconSize`, as the List lens's expense rows | `LookBackCategoryRowView` |
| A simulator seed for every rule | `-seedPlanData look-back` copies the next cycle's plan, then moves this one on without it | `DebugPlanSeed.seedLookBack` |
| The derivation | Pure and tested against flow AB's sample, one test per rule | `LookBack`, `LookBackTests` |
