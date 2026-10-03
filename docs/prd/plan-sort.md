# PRD — Sorting the Plan

Status: Accepted
Date: 2026-10-03 · design approved the same day (flow M)
Owner: Randy Efan

Companion documents: `docs/prd/payday-planning.md` (the Plan lens this changes),
`CONTEXT.md` (ubiquitous language), and **`design/ExpenseKu.pen`**, page
`05 · Proposals — not built`, **Flow M**. Frame references appear inline as `[→ M2]`.

---

## 1. What this is

The Plan lens lists a cycle's PlanItems in exactly one order: **amount descending**,
matching the spreadsheet (`payday-planning.md` §9.1). On payday the owner works through
the plan account by account — six banking apps open — and with one fixed order the items
for one bank are scattered across a 14-row list.

This feature lets the owner choose how the plan's items are ordered and, for three of
the orders, grouped.

## 2. Goals

1. See every item paid from or kept in one Account together.
2. Offer the other readings the owner asked for in the same control: Group, due day,
   status and name.
3. Change nothing about what the plan *is*. Sorting is a view, like the Funded filter:
   Sisa, totals, the transfer checklist and the share table never move.

## 3. Non-goals

- **Remembering the choice.** Not across launches, not across cycles (§5).
- **Sorting the dormant section.** "From last cycle" keeps its own order (§6).
- **Sorting income lines, transfer lines or the share table.**
- **Subtotals in group headers.** The transfer checklist and share table already carry
  per-Account and per-Group totals; the headers carry a count only.
- **Ascending/descending toggles.** Each order has one direction.

---

## 4. The six orders

The control is a Menu at the trailing end of the **`PLAN · N ITEMS`** section header,
labelled with the active order. `[→ M1]`

| Order | Shape | Groups, in order | Items within |
|---|---|---|---|
| **Amount** *(default)* | flat | — | amount ↓ · name · created — unchanged from today |
| **Account** | grouped | Account by planned total ↓, name; **Unassigned** last | due day in cycle |
| **Group** | grouped | Group by planned total ↓, name; **Ungrouped** last | due day in cycle |
| **Due day** | flat | — | due day in cycle |
| **Status** | grouped | **Todo → Funded → Done** | due day in cycle |
| **Name** | flat | — | `localizedStandardCompare`, then amount ↓ |

`[→ M2 Account, M3 Group, M4 Due day, M5 Status]`. Name is flat like Amount and needs no
frame of its own.

### 4.1 "Due day in cycle"

Due days order by **where they fall inside the cycle**, not by the day-of-month number.
With payday 25, a cycle runs 25 Oct → 24 Nov, so day 25 comes first and day 24 last:

```
25 · 28 · 1 · 5 · 12 · 24 · (no due day)
```

The date is resolved with the existing `DueDay` clamp, so a day 31 in a 30-day month
sorts as the 30th. An item with no due day — and one whose due day resolves to nothing,
the walking payday-31 case in `payday-planning.md` §11.5 — sorts **after** every dated
item. Envelopes never have a due day, so they always sit at the foot of their group.

Ties, and the undated tail, break on **amount ↓ · name · created**, the existing sort,
so the order is stable across launches and devices.

### 4.2 Group headers

Each group gets a section header, **`NAME · N ITEMS`**, in the existing
`SectionHeaderText` style, led by a small glyph that says which order is showing: the
Account's own symbol, the Group's symbol in the Group's tint, or the state's glyph
(◯ Todo, ↓ Funded in the accent, ✓ Done in the positive green). The top `PLAN · N ITEMS` header stays above the first group and
keeps the control. Empty groups are never shown. A grouped order with a single group
still shows that group's header. `[→ M2]`

- **Account** — the item's Account. None: **Unassigned** (CONTEXT.md).
- **Group** — through `GroupShares.group(of:)`, so an Envelope spanning two Groups lands
  in the one most of its categories share, exactly as the share table counts it. None:
  **Ungrouped**.
- **Status** — the item's effective state (`payday-planning.md` §7.6): Todo, Funded,
  Done. An Envelope never reaches Done. A posted Auto item is Done; an unposted Auto
  item is Todo, or Funded when its account is covered.

Ordering Account and Group groups by planned total makes the list read in the same order
as the transfer checklist and the share table below it.

**Rows do not change.** Grouped by Account, every row still carries its Account chip,
though the header already names it: a row is one component in every order, and a chip
that comes and goes with the sort would make the same item look different between two
screens.

---

## 5. Lifetime

The order is **session view state**, held beside the Funded filter, never stored.

| Event | Order afterwards |
|---|---|
| App relaunched | Amount |
| Paging to another cycle (`‹ ›`) | Amount |
| Switching lens and back | kept |
| Tapping the funded notice (filter on) | Amount, control hidden `[→ M6]` |
| ✕ on the funded filter | Amount |

While the Funded filter is on, the plan is always in Amount order and the control is not
shown: the filter answers its own question and the two do not combine.

## 6. Unaffected

- **Dormant** — "From last cycle" keeps amount ↓ and stays one folded section.
- **Totals, Sisa, the cycle header, notices** — a sort moves rows, nothing else.
- **Transfer checklist and share table** — unchanged, still at the foot.
- **Reveal animation** — once per section, as today, so a grouped plan does not cascade
  one reveal per group.

---

## 7. Decision log

Settled in a grilling session on 2026-10-03. Entries 17–18 were settled when the owner
approved flow M the same day.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Sorting by Account **groups** with a header per Account, rather than reordering a flat list | `M2` |
| 2 | Six orders: Amount, Account, Group, Due day, Status, Name | `M1` |
| 3 | Due day is **flat**, no header per date | `M4` |
| 4 | Due day orders by **position in the cycle**, not day-of-month | `M4` |
| 5 | Group headers read **`NAME · N ITEMS`** — no subtotal | `M2`, `M3`, `M5` |
| 6 | The control lives in the **`PLAN · N ITEMS` header** as a Menu | `M1` |
| 7 | The order **resets to Amount** on relaunch — *owner override*, against remembering it per device | — an absence |
| 8 | Paging to another cycle **resets** to Amount — *owner override*, against keeping it for the session | — |
| 9 | The Funded filter **forces Amount** and hides the control — *owner override*, against sorting the filtered list | `M6` |
| 10 | ✕ on the filter leaves **Amount** — *owner override*, against restoring the earlier order | — |
| 11 | Dormant rows are **not** sorted | `M2` |
| 12 | Account and Group groups order by **planned total ↓**; Unassigned/Ungrouped last | `M2`, `M3` |
| 13 | Status groups order **Todo → Funded → Done** | `M5` |
| 14 | Items within a group order by **due day in cycle** — *owner override*, against amount ↓ | `M2` |
| 15 | The menu says **Account**, not "Bank" | `M1` |
| 16 | This is its own PRD, not an amendment to `payday-planning.md` — *owner override* | — |
| 17 | Group headers lead with a glyph — Account symbol, Group symbol in its tint, state glyph | `M2`, `M3`, `M5` |
| 18 | Rows are unchanged in every order; the Account chip stays when grouped by Account | `M2` |

`payday-planning.md` §9.1 ("plan rows sort by amount descending") now describes the
**default** order, not the only one.

---

## 8. Design traceability

Page `05 · Proposals — not built`, **Flow M · Plan sort**.

| Frame | Covers |
|---|---|
| **M1** · Tap the order — the menu | §4 control, decision 6, 15 |
| **M2** · By Account | §4.2 headers, Unassigned last, items by due day, dormant untouched |
| **M3** · By Group | §4.2 Envelope attribution, Ungrouped last |
| **M4** · By Due day | §4.1 cycle position, undated tail |
| **M5** · By Status | §4.2 Todo → Funded → Done |
| **M6** · Funded filter — no control | §5, decision 9 |
