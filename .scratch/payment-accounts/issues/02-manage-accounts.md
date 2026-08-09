# 02 — Manage Accounts screen + AccountPicker

Status: ready-for-agent
Blocked by: 01

CRUD for accounts and the single-select picker, mirroring Categories.

## Scope

- `Features/Accounts/ManageAccountsView.swift` — list (sorted by name), add/rename via
  `NameEditorView<Account>` (de-dup prompt, ADR-0002), swipe-delete (nullify, ADR-0001).
- `Shared/AccountPicker.swift` — single-select, pops on selection, inline "New Account"
  through the de-dup editor (clone of `CategoryPicker`).
- Add an **Accounts** row to `ManageView` (Categories · People · Accounts), including the
  `-startScreen accounts` DEBUG deep-link for parity.

## Definition of done

- Owner can maintain accounts and never accidentally create a duplicate.
- Builds on the iOS 17 simulator.

## Comments
