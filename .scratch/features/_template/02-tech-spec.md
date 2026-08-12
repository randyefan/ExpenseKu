# 02 — Tech spec · <feature-slug>

## Data model
<!-- New/changed SwiftData @Model types, fields, defaults, migration notes. -->

## Files touched
<!-- Concrete list. Mark (new) / (edit). -->
- `ExpenseKu/ExpenseKu/...` (new)

## Control surface (so the screen is screenshot-able)
- `-startScreen <value>` — add to `Shared/DebugLaunch.swift` doc-comment
- `case "<value>":` in `Shared/DebugHarness.swift` → builds `<View>`
- if fullScreenCover: add `<value>` to `RootView.debugScreens`

## Fixtures
<!-- What to add to DebugLaunch.seedIfNeeded so the screen has realistic data + an edge case. -->

## Test plan (behaviour oracle)
<!-- The unit tests that will prove correctness. Write these first in stage 3. -->
- [ ]

## Interactive flow (simdrive.sh — required)
<!-- The exact tap/key sequence Stage 3 runs to verify behaviour in the app. Coords are
     screenshot pixels; state the expected result after each step. See AGENTS.md. -->
- `simdrive.sh launch -- -startScreen <value>`
- [ ] `tap <px> <py>` → expect <state change>
- [ ] ... → expect ...

## Risks / guardrails touched
<!-- Anything near the revamp guardrails (model/vocab/3-tab/money format). -->

---
Gate 2: user agrees the approach is sound before any code is written.
