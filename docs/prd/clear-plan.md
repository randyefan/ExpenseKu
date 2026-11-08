# PRD — Clearing an upcoming plan

Status: Built
Date: 2026-11-09 · design approved and built the same day (flow AH)
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Plan lens and carry-over this
changes, §7.1–§7.2), `docs/prd/set-aside.md` §4.9 and `docs/prd/envelope-assignment.md`
(the links a cleared plan lets go of), `CONTEXT.md` (ubiquitous language), and the Wonder
file **ExpenseKu**, proposals page, **Flow AH · Clear plan**. Frame references appear
inline as `[→ AH2]`.

---

## 1. What this is

A plan for an upcoming cycle is built by carry-over the first time the owner pages to it
and opens the Plan lens (`payday-planning.md` §7.2). Once it exists nothing rebuilds it,
and today nothing removes it either: a January the owner opened in November, before
December was settled, stays a copy of November for good. Deleting it row by row is the
only way out.

This feature lets the owner **clear** the plan of the upcoming cycle on screen: the plan
is deleted and the cycle goes back to having no plan. With it, carry-over stops being
automatic. A cycle with no plan offers **Copy from <month>** and **Start empty**, for every
cycle, so a cleared cycle is never silently refilled when the owner pages back to it.

## 2. Goals

1. One action, from the Plan lens, that empties an upcoming cycle's plan.
2. Say before it happens what else the clear lets go of — expenses paid early into its
   envelopes, set-asides from earlier plans, items already Done.
3. Never lose an Expense (ADR-0001).
4. Let the owner choose, per cycle, between a fresh copy and a blank plan.

## 3. Non-goals

- **Clearing the current or a past cycle.** Those plans hold what actually happened.
- **Clearing several cycles at once.** One cycle, the one on screen — *owner override*.
- **Re-copying in place.** Clear deletes; refilling is a second, separate tap.
- **Undo.** The confirmation alert is the guard.
- **Clearing only items, or only income lines.** The whole plan goes.

---

## 4. The rules

### 4.1 Where Clear Plan lives

A **`…` toolbar button** (`ellipsis`, labelled "Plan options", the same glass circle as
Search) sits in the primary-action slot before **＋**, and its Menu holds one entry:
**Clear Plan**, role destructive, with the `trash` glyph. The open menu is the system menu
and may cover the cycle title. `[→ AH1]`

| Condition | `…` shown |
|---|---|
| Lens is **Plan**, cycle on screen starts **after** the current cycle, the cycle has a plan | yes |
| Lens is List or Month | no |
| Current cycle, or any past cycle | no |
| Upcoming cycle with no plan | no |
| List selection mode (Select All / Done toolbar) | no — that toolbar replaces the whole bar |

"Upcoming" is `cycle.start > PayCycle.containing(.now, payday:).start`, read off the same
Payday anchor as the header.

### 4.2 The confirmation

Clear Plan opens a destructive alert. `[→ AH2]`

- **Title:** `Clear <Month>'s plan?` — the month as the cycle header names it (the month
  the cycle ends in).
- **Body**, built from up to three sentences, each present only when it has something to say:

| Sentence | Present when | Example |
|---|---|---|
| `<n items>, <n rows from last cycle> and <n income lines> will be deleted.` | always; a zero part is dropped, all zero reads `The plan will be deleted.` Items count as the plan header does; dormant rows are named apart | `14 items, 11 rows from last cycle and 2 income lines will be deleted.` |
| `<links> will lose their place in it.` | any of the links below exist | `1 expense paid early and 1 set-aside from December will lose their place in it.` |
| `Expenses are kept.` | any Expense is among the links | — |

The links, in this order, each phrase omitted at zero:

| Phrase | Counts |
|---|---|
| `<n> expense(s) paid early` | Expenses **assigned** to this plan's envelopes (any cycle) |
| `<n> expense(s) marked done` | Expenses linked to this plan's Fixed items |
| `<n> set-aside(s) from <Month>` | Set-aside items in **other** plans whose target is in this plan; `from earlier cycles` when they come from more than one |

- **Buttons:** `Cancel` (cancel role) and `Clear Plan` (destructive). `[→ AH2, AH2b]`

### 4.3 What clearing does

The plan is deleted. Its items, income lines and transfer lines cascade with it, as the
model already declares. Every other link nullifies (ADR-0001):

| Link | After the clear |
|---|---|
| Expense assigned to one of its envelopes (paid early, or in its own cycle) | kept; assignment gone, back to **by category** — Outside plan in its own cycle unless an envelope there claims it |
| Expense created by one of its Done items | kept in the ledger, no longer linked |
| Set-aside line in an earlier plan targeting one of its envelopes | kept, target nil — the existing `set-aside.md` §4.9 warning state; still debits its own plan |
| Set-aside line *in* this plan | deleted with it; the later plan it fed loses that money in its Sisa |
| Paid early *out of* this plan's cycle into a later plan | untouched — that is an Expense of this cycle, not part of its plan |

The Plan lens then shows the no-plan state for that cycle (§4.4) with the `…` button gone.
`[→ AH3]`

### 4.4 A cycle with no plan

Carry-over no longer runs on arrival — *owner override*. `ExpensesView.carryOverIfNeeded`
goes away; `PlanCarryOver.makePlan` runs only from a button. Every cycle without a plan,
upcoming, current or past, shows the no-plan state: `[→ AH3, AH4]`

| Earlier plan exists | Message | Buttons |
|---|---|---|
| yes | `Copy <Month>'s plan and adjust it, or start from nothing.` | **Copy from <Month>** (primary, accent capsule, on top) · **Start empty** (secondary: surface capsule with a hairline, below) |
| no — the owner's first plan | `Start one for this cycle. Every cycle after it can copy it in one tap.` | **Start this cycle's plan** (primary) |

- **<Month>** is the most recent plan *before* this cycle (`PlanLookup.source(before:)`),
  skipping cycles without one, named as the cycle header names it.
- **Copy from** is today's carry-over, unchanged (`payday-planning.md` §7.2): the source as
  it is now, progress cleared, set-asides not copied, Rp 0 rows dormant. The carry-over
  notice `Copied from <Month> — …` appears as it does today. `[→ AH5]`
- **Start empty** creates an empty plan, exactly as **Start this cycle's plan** does.
- The cycle header shows `SISA Rp 0`, as it does today for a cycle without a plan.
- The title stays `No plan yet` in every case.

### 4.5 Consequences of manual carry-over

| Situation | Before | Now |
|---|---|---|
| Owner pages to next cycle, Plan lens | plan copied on arrival | no-plan state; one tap copies |
| Owner never opens the next cycle's plan | no plan, Auto items do not fire | same |
| Cleared cycle, owner pages away and back | — | still no plan |
| Past cycle with no plan | `Start this cycle's plan` | Copy from / Start empty when an earlier plan exists |

`PlanEmptyState`'s copy, *"…then every cycle after it is copied forward automatically"*,
is no longer true and is replaced by §4.4's.

---

## 5. Lifetime

Clearing is a write, not view state. It is synced like any delete.

| Event | Effect |
|---|---|
| Clear, then page away and back | no-plan state, `…` hidden |
| Clear, relaunch | no-plan state |
| Clear on one device | the other device's Plan lens shows the no-plan state on its next sync |
| Payday changed after a clear | nothing to re-home; the cycle has no plan |
| Upcoming cycle becomes the current one | `…` disappears; the plan can no longer be cleared |

## 6. Interactions and unaffected

| Feature | With Clear Plan |
|---|---|
| Plan sort, plan filter, Funded filter | session state keyed to the cycle; nothing left to sort or filter |
| Look back | shown only when a plan exists, as today |
| Carry-over notice | belongs to the deleted plan; reappears after Copy from |
| Expense filter, List and Month lenses | unaffected; the toolbar's `…` is Plan-only |
| `CyclePaging.canGoBack` | unaffected: only upcoming plans can be cleared, never the oldest |
| Insights | unaffected — a plan is not a ledger (ADR-0005) |

---

## 7. Decision log

Settled in a grilling session on 2026-11-09.

| # | Decision | Drawn in |
|---|---|---|
| 1 | "Reset" **deletes** the plan, leaving no plan — *owner override*, against re-copying from the current plan | `AH3` |
| 2 | Clears **only the cycle on screen** — *owner override*, against every cycle after the current one | `AH1` |
| 3 | A cycle with no plan offers **Copy from <Month>** and **Start empty** — *owner override*, against keeping an empty plan | `AH3` |
| 4 | Carry-over is **manual for every cycle** — *owner override*, against staying automatic except for cleared cycles | `AH3`, `AH5` |
| 5 | The action lives in a **`…` toolbar menu**, Plan lens only — *owner override*, against a row at the plan's foot | `AH1` |
| 6 | Confirmation is a destructive alert that **counts** what is deleted and what loses its link | `AH2` |
| 7 | The word is **Clear Plan** | `AH1`, `AH2` |
| 8 | Only **upcoming** cycles with a plan can be cleared; `…` is hidden otherwise | `AH1` |
| 9 | Expenses are never deleted; every link nullifies (ADR-0001) | `AH2` |
| 10 | Copy from takes the **most recent earlier plan**, skipping gaps, with today's carry-over rules | `AH5` |
| 11 | With no earlier plan, only **Start this cycle's plan** | `AH4` |
| 12 | The no-plan state is the same in past cycles | — |
| 13 | The carry-over notice still appears after Copy from | `AH5` |
| 14 | No undo | — |
| 15 | `…` is the Search-style glass circle, placed before ＋ | `AH1` |
| 16 | The menu row is red with a trash glyph; the open menu may cover the cycle title | `AH1` |
| 17 | Alert buttons: Cancel (accent, bold) beside Clear Plan (red); links "lose their place in it", so Done items read right | `AH2` |
| 18 | Copy from is the primary button, on top; Start empty the secondary one below | `AH3` |
| 19 | A cycle without a plan shows `SISA Rp 0` | `AH3`, `AH4` |
| 20 | The no-plan messages as worded in §4.4 | `AH3`, `AH4` |

Entries 15–20 are design calls approved with flow AH on 2026-11-09.

## 8. Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| The alert counted every row (25) while the plan header said 14 ITEMS | Items count as the header does; dormant rows are named apart as "rows from last cycle", the section's own words | `PlanClearing.reach`, `testDormantRowsAreCountedApartFromItems` |
| An empty plan made with Start empty is still a plan | `…` shows and Clear Plan works; the alert reads `The plan will be deleted.` | simulator, `testZeroPartsAreDroppedAndAnEmptyPlanSaysSo` |
| `…` took the toolbar's accent tint | Tinted `Theme.text`, as drawn | `ExpensesView` toolbar |
| The carry-over notice names the source with its year ("November 2026") while Copy from names the month alone | Left as is: the notice is unchanged carry-over copy | — |
| Wonder's page 02 has no shipped flows yet (AG still waits there too) | Flow AH stays on page 05, marked built, until the page 02 move happens for both | Wonder |

## 9. Design traceability

| Frame | Settles |
|---|---|
| `AH1` | January 2027 plan, `…` menu open on Clear Plan |
| `AH2` | the confirmation alert with all three sentences |
| `AH2b` | the same alert with no links: one sentence |
| `AH3` | January after the clear: No plan yet, Copy from December / Start empty |
| `AH4` | the first cycle ever: Start this cycle's plan, revised message |
| `AH5` | January after Copy from December, carry-over notice |
