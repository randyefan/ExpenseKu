# 00 — Brief · expense-time

## Problem
When adding an expense I can pick the **day** but not the **time of day**. Every new
expense silently takes the current clock time, and there's no way to set or correct it.
So when I log several expenses on the same day (or back-fill a past day), I can't control
their order in the list — they sort by a time I never chose.

I want to input the time so the expenses list sorts meaningfully within a day.

## Who it's for
The owner entering or editing an expense — especially when logging multiple expenses on
one day, or entering something after the fact for an earlier moment.

## Acceptance criteria
- [ ] The expense editor lets me set a **time** (hour + minute) in addition to the date.
- [ ] The time I set is saved on the expense.
- [ ] Editing an existing expense shows and preserves its current time; changing it updates it.
- [ ] A new expense defaults to the current time (today's behaviour), and I can change it.
- [ ] The expenses list orders same-day expenses by the time I set (newest first),
      consistent with the existing reverse-chronological ordering.

## Out of scope
- No change to the day-grouping of the list or the pay-cycle paging.
- No timezone handling beyond the device's current calendar (today's behaviour).
- No "sort mode" toggle — ordering stays newest-first by timestamp.
- No changes to the money model, vocabulary, or the 3-tab shell.

---
Gate 0: user confirms "this is the feature." Do not start wireframes until approved.
