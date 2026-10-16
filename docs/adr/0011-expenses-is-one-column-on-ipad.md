# ADR-0011 — The Expenses tab is one column on iPad too

Status: Accepted
Date: 2026-10-17
Supersedes: the "iPhone push / iPad-Mac split" rule in `docs/design-brief.md` §2 and §5

## Context

On iPad the Expenses tab was a `NavigationSplitView`: the cycle list in the sidebar,
the expense editor in the detail pane. Run on an iPad Pro 11" it read as broken:

- iPadOS keeps the sidebar at 320pt. `navigationSplitViewColumnWidth` only narrows it;
  `min: 340, ideal: 400` and a fixed `400` were both ignored, in portrait and landscape.
- At 320pt the List / Month / Plan toggle truncated to "Li… M… Pl…" and a row's note,
  account and people wrapped onto three lines.
- Two thirds of the screen showed "No Expense Selected" until a row was tapped, and kept
  showing a previous cycle's expense after paging away.
- Inside a `TabView`, iPadOS 26.4+ reserves an empty band above the sidebar's toolbar
  (FB22645938; Apple says iPadOS 27 removes it).

## Decision

**One column on every device.** The tab is a `NavigationStack`, as on iPhone. On iPad
its content centres at `Metric.readableWidth` (720pt), the same cap Insights and Manage
now use, and both add and edit open the editor as a page-sized sheet, with the keypad
following the form instead of docking at the bottom of a tall sheet.

## Consequences

- Rows, the lens toggle and the header get the full readable width; nothing truncates.
- No empty detail pane, no stale editor after paging, no sidebar inset bug.
- Editing covers the list instead of sitting beside it. The owner accepted that trade
  for a layout that is consistent with iPhone and with the other two tabs.
- The Designed-for-iPad Mac build gets the same single column.
