# 01 — Design: architecture, UX flows & data schema

Status: ready-for-agent

Design the app before implementation. This is a collaborative design ticket — the agent proposes, the owner decides. Output is written design artifacts the implementation tickets (02–08) depend on.

See `../spec.md` for v1 scope and `CONTEXT.md` (repo root) for the ubiquitous language.

## Produce

1. **Navigation & screen map** — the top-level structure across iPhone / iPad / Mac (e.g. tabs vs sidebar), and every screen: expense list, add/edit expense, manage categories, manage people, analytics. Note how the adaptive layout differs per device.

2. **Add-expense flow** — the fastest path to log an expense on iPhone. Where category/person pickers live, how inline-create works, what's default-filled.

3. **SwiftData schema** — concrete `@Model` definitions for Expense, Category, Person with relationship declarations, honoring the SwiftData+CloudKit constraints (all properties optional-or-defaulted, no unique constraints, relationships optional).

4. **Module / file structure** — how the multiplatform target is organized (models, views, analytics/query layer, shared components).

5. **Resolve the open edges** (from spec):
   - **Delete semantics** — what happens to expenses when a referenced Category or Person is deleted.
   - **De-dup UX** — how pick-from-existing prevents duplicate Category/Person records given no unique constraints.

## Definition of done

- Design captured as a doc (e.g. `.scratch/expense-tracker-v1/design.md`) and/or ADRs under `docs/adr/` for the decisions with lasting consequence (delete semantics, de-dup approach).
- Open edges in the spec are resolved and the spec/CONTEXT updated to match.
- Tickets 02–08 are unblocked (their "Blocked by: 01" removed) once this is accepted.

## Comments
