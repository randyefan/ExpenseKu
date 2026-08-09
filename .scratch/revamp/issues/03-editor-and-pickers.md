# 03 — Expense editor + pickers + name-duplicate prompt (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/expense-editor.png`, `refs/picker-category.png`, `refs/picker-people.png`, `refs/name-duplicate.png`
Files: `Features/Expenses/ExpenseEditorView.swift`, `Shared/CategoryPicker.swift`,
`Shared/PeoplePicker.swift`, `Shared/AccountPicker.swift`, `Shared/NameEditorView.swift`

Reskin the add/edit editor (amount hero + date, Category required, Account "None", People
"None", multi-line note, Delete when editing, Save/Cancel) and the pushed pickers (single-select
w/ coral checkmark + "New …"; People multi-select) and the "'X' already exists" prompt
(Use existing / Create new anyway / Cancel).

## Verify
Seed, open editor from home + drive into each picker; screenshot each vs its ref. `-a` for dark.
`scripts/shot.sh --test`.

## Guardrails
Keep required-field logic (Save disabled until amount > 0 AND category chosen), the dedup prompt
(ADR-0002), amount auto-focus on add. Behaviour unchanged.
