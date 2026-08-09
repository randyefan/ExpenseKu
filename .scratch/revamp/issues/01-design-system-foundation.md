# 01 — DesignSystem foundation (Warm Cards)

Status: ready-for-agent
Blocks: 02, 03, 04, 05, 06, 07, 08

Build the shared design layer every other ticket depends on. **Land this first, alone** — it
touches `project.pbxproj` + `Info.plist`, so fan-out only after it merges.

## Deliverables
Create `ExpenseKu/ExpenseKu/DesignSystem/`:
- `Theme.swift` — color tokens from `spec.md` (light + dark). Prefer an asset catalog color set
  (auto dark mode) or a `Color` extension keyed off `@Environment(\.colorScheme)`.
- `Typography.swift` — Plus Jakarta Sans registered + a type scale (title/headline/body/caption).
  Bundle the `.ttf` files, add `UIAppFonts` to `Info.plist`, register on macOS too. Provide a
  `.jakarta(_:weight:)` font helper. Amount style = weight 700 + `.monospacedDigit()`.
- `Spacing.swift` — radius 16, padding 16, gap 12 constants.
- `Components.swift` — reusable modifiers/views: `CardStyle`, `SectionHeaderStyle`,
  `MoneyText`, `EmptyStateView`, `CategoryIcon` (pastel circle), `AccentButton`.

## Acceptance
- App builds + launches on the simulator with the new tokens applied to at least the tab bar
  tint (coral active tab) — proves fonts + colors load.
- Dark mode tokens resolve.
- `scripts/shot.sh ds-smoke -- -seedSampleData` produces a screenshot on cream bg with a coral
  active tab; `-a` variant reads in dark.
- Existing tests green (`scripts/shot.sh --test`).

## Guardrails
Style only. No behaviour, model, or navigation changes. Keep Dynamic Type + VoiceOver working;
don't hardcode sizes that break Dynamic Type.
