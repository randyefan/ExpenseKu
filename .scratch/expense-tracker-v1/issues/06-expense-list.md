# 06 — Expense list

Status: resolved

Chronological list of expenses as the app's home surface.

## Scope

- Reverse-chronological list showing amount, date, category, and tagged people per row.
- Tap a row to edit (ticket 05).
- Adaptive layout per device per ticket 01 (e.g. list + detail on iPad/Mac).

## Definition of done

- All logged expenses are visible, readable at a glance, and navigable to edit.

## Comments

- 2026-08-09: Reopened after the basic list shipped inside ticket 05. Replaced `ContentView` with `Features/Expenses/ExpensesView`: a single `NavigationSplitView` that adapts per device — list+detail on iPad/Mac, collapsed push on iPhone. Reverse-chronological, **grouped by month**. Add stays a sheet (fast-add). `ExpenseEditorView` gained an `onFinish` hook so it works both as a sheet/push (dismiss) and as a detail pane (clears selection); `.id(persistentModelID)` resets editor state when switching rows. Two deviations from the original design.md §1 recorded there: iPhone **edit** is a push (not a sheet), and per-tab navigation rather than one global sidebar (deferred). Verified **BUILD SUCCEEDED** on the iOS 17 simulator.
