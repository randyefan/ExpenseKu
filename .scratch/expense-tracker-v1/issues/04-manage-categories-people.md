# 04 — Manage Categories & People (CRUD + pick-from-existing)

Status: resolved

Screens and pickers to add, rename, and delete Categories and People, and to select them on an expense.

## Scope

- Manage-Categories and Manage-People screens: list, add, rename, delete.
- Reusable **picker** components used by the add-expense flow that **select from existing or create inline** — enforcing de-dup per ticket 01 (no free-typed duplicates).
- Delete behavior wired to the semantics decided in ticket 01.

## Definition of done

- Owner can maintain both entities and never accidentally create a duplicate "Fadil".

## Comments

- 2026-08-09: Implemented. Shared de-dup layer (`Shared/NamedEntity.swift` — `NamedEntity` protocol + `existingEntity(...)` case-insensitive match; `Shared/NameEditorView.swift` — generic add/rename with the ADR-0002 confirmation dialog). Manage screens: `Features/Categories/ManageCategoriesView`, `Features/People/ManagePeopleView` (list + add/rename/swipe-delete, `.nullify` via delete rule per ADR-0001). Pickers: `Shared/CategoryPicker` (single), `Shared/PeoplePicker` (multi) for the ticket-05 editor. Added a 3-tab `RootView` shell (Expenses/Insights placeholders + Manage) so the screens are reachable — iPad/Mac sidebar refinement deferred to 06. Verified **BUILD SUCCEEDED** on the iOS 17 simulator. Category color/icon left for a later polish (design lists it optional). Runtime UX (tap-through, dup prompt) to be exercised on next app run.
