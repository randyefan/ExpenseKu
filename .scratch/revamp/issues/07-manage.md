# 07 — Manage (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/manage.png`
Files: `Features/Manage/ManageView.swift`, `Features/Categories/ManageCategoriesView.swift`,
`Features/People/ManagePeopleView.swift`, `Features/Accounts/ManageAccountsView.swift`

Reskin the Manage menu (Categories / People / Accounts) and each list: add (+), tap-to-rename,
swipe-to-delete, and an empty state per list, in Warm Cards styling.

## Verify
`scripts/shot.sh manage -- -seedSampleData -startTab manage` vs `refs/manage.png`.
Also `-startScreen categories|people|accounts`. `-a` for dark. `scripts/shot.sh --test`.

## Guardrails
Keep add/rename/delete + nullify-on-delete semantics (ADR-0001) and each empty state. Behaviour unchanged.
