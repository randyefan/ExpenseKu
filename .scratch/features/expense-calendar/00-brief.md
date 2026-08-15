# 00 — Brief · expense-calendar

## Problem
The Expenses tab is a single vertical lens: one pay cycle, a hero total, then a flat
day-grouped list. To answer "what did I spend on the 14th?" or "which days this cycle
were heavy?" you have to scroll the list and read day headers one by one. There is no
way to *see the shape of a period at a glance* — which days had spending, which were
quiet, which were the spikes. The user wants a calendar view in the Expenses tab so
they can see their expenses laid out by date.

## Who it's for
The everyday logger who already lives in the Expenses tab. They log as they go, then
later want to look back date-first — "I remember eating out last week, which day was
that?" — instead of amount-first or list-first.

## Acceptance criteria
- [ ] The Expenses tab offers a **calendar view** alongside the existing day-grouped
      list; the user can switch between them and the choice sticks while the app runs.
- [ ] The calendar lays out the current pay cycle's days in a month-style grid, so the
      user can see the whole period at once.
- [ ] Each day cell shows whether that day has spending and how much — the day's total,
      abbreviated to thousands, printed under the date. A day with expenses is visually
      distinct from an empty day, and the distinction is not carried by color alone
      (guardrail): heavier days are set in a heavier weight as well as a darker tone.
- [ ] Tapping a day shows that day's expenses (title/merchant, category, time, amount),
      with the day's total.
- [ ] The existing ‹ › pay-cycle paging still drives the calendar: paging changes which
      period the grid shows, and the hero spending total stays correct and unchanged.
- [ ] Days outside the current pay cycle are visibly de-emphasised (or absent), so the
      cycle boundary is still legible — the pay-cycle model is not replaced by a
      calendar month.
- [ ] Empty state: a cycle with no expenses still renders the grid, with a clear
      "nothing logged" message rather than a blank screen.
- [ ] From a selected day the user can still open an expense in the editor (tap a row),
      and can still add a new expense with +.
- [ ] Dark mode, Dynamic Type and VoiceOver all work: each day cell is announced with
      its date and its total (or "no expenses").
- [ ] Existing tests stay green; the day-grouping/pay-cycle behaviour is unchanged.

## Out of scope
- Any new spending concept — no budget, remaining, income, net, or per-day limits
  (revamp guardrail).
- Editing or moving an expense by dragging it between days.
- A week view, an agenda view, or multi-month scrolling.
- Changing the pay-cycle model itself, the hero total, or the 3-tab shell.
- Adding a calendar to Insights (this is the Expenses tab only).

## Decisions (settled at gate 0, 2026-08-16)
1. **Grid period** — **pay-cycle aligned**. The grid spans the active cycle (e.g. 25 Jul →
   24 Aug, honouring Monthly Start Date); days outside it are greyed. The grid and the hero
   total always cover the same range.
2. **How the two views coexist** — a small **list/calendar toggle in the header**. The list
   stays the tab's default; the choice sticks for the session.
3. **What a day cell shows** — ~~date number + intensity dot~~ **superseded 2026-08-16 during
   stage 3**: the owner asked for the day's **total printed under the date** instead. A ~48pt
   column can't hold "Rp145.000", so it is **abbreviated to thousands ("145k")** and the
   intensity ramp moves from dot *size* to the number's *weight + tone* — so the grid still
   shows the shape of the cycle at a glance and meaning still isn't carried by color alone.
   At accessibility text sizes the total is dropped and the date bolds instead (unchanged).

---
Gate 0: user confirms "this is the feature." Do not start wireframes until approved.
