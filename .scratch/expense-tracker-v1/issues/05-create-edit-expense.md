# 05 — Create / edit / delete an Expense

Status: resolved

The core logging loop: the add/edit-expense screen and flow.

## Scope

- Fields: amount, date (defaults to now), category (pick/create), people (pick/create, zero+), note.
- Fastest-path add flow on iPhone per ticket 01's design.
- Edit and delete existing expenses.
- Money entry uses `Decimal`, formatted for IDR.

## Definition of done

- Owner can log a fully-tagged expense in seconds and edit/delete it afterward.

## Comments

- 2026-08-09: Implemented `Features/Expenses/ExpenseEditorView` (add/edit; amount auto-focused per design.md §2, date-only DatePicker, required Category via `CategoryPicker`, optional People via `PeoplePicker`, note; delete button in edit mode). Wired into the Expenses tab (`ContentView`): + to add, tap row to edit, swipe to delete. Basic `ExpenseRow`. Shared helpers: `Money.formattedIDR()` (zero-fraction rupiah) and `decimalKeyboard()` (cross-platform). `CategoryPicker` now pops on select. Verified **BUILD SUCCEEDED** on the iOS 17 simulator. Runtime tap-through/persistence to be exercised on next app run; list polish is ticket 06.
