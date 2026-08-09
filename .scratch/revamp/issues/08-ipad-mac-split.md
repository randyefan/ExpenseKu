# 08 — iPad / Mac split view (reskin + adaptivity check)

Status: ready-for-agent
Blocked by: 01, 02, 03
Refs: `refs/desktop-split.png`
Files: `RootView.swift`, `Features/Expenses/ExpensesView.swift`, `Shared/PlatformModifiers.swift`

Ensure the Warm Cards styling degrades to the two-column (list + detail) layout on iPad/Mac:
selecting an expense row opens the editor in the right pane; "No Expense Selected" placeholder
when nothing is picked.

## Verify
Run on an iPad simulator: `scripts/shot.sh ipad-split -d "iPad Pro 13-inch (M4)" -- -seedSampleData`
vs `refs/desktop-split.png`. `-a` for dark. `scripts/shot.sh --test`.

## Guardrails
Keep iPhone-push vs iPad/Mac-split adaptivity. No behaviour change; this is layout + style only.
Do this last — it depends on the reskinned home (02) and editor (03).
