# AGENTS.md — ExpenseKu "Warm Cards" revamp harness

**If you are an agent working on this revamp, read this file first.** It tells you how to
drive the harness on your own: what to read, what to run, and how to judge the result.

## What this is

A **visual verify loop** for reskinning ExpenseKu to the approved "Warm Cards" direction
**without changing behaviour, flow, navigation, or vocabulary**. You edit SwiftUI, drive the
app to a known screen via launch args, screenshot it, and compare against a frozen mockup.

- **Working directory for all commands: the repo root** (`ExpenseTracker/`), not this folder.
- All harness files live under `.scratch/revamp/`. The runner is `scripts/shot.sh`.

## Read these before touching code

1. **`.scratch/revamp/spec.md`** — design tokens + the hard guardrails. Non-negotiable.
2. **`.scratch/revamp/issues/NN-*.md`** — the ticket you're working. Each names its ref
   image, its launch args, and its done-criteria.
3. **`.scratch/revamp/refs/*.png`** — the frozen Stitch mockups = **source of truth**.

## The loop (repeat until the ticket's done-criteria are met)

1. Read the ticket in `issues/` and its ref image(s) in `refs/`.
2. Edit SwiftUI — design tokens + components live in `ExpenseKu/ExpenseKu/DesignSystem/`.
3. Screenshot: `scripts/shot.sh <name> [-a] [-- <launch args>]` → writes `shots/<name>.png`.
4. **Verify (visual oracle):** Read `shots/<name>.png`, compare to the ref. Match the
   *design* (layout / spacing / colour / hierarchy), **not the bytes** — sample data and
   fonts differ from the mockup on purpose. Refine and repeat.
5. Also shoot dark mode (`-a`) and confirm it reads.
6. **Verify (behaviour oracle):** `scripts/shot.sh --test` — unit tests must stay green.
7. Commit (one commit per ticket).

## Two oracles — do not confuse them

| Question | Oracle | How |
|----------|--------|-----|
| "Does it *look* right?" | ref PNGs | Read `shots/*.png`, eyeball vs `refs/*.png` |
| "Does it *work*?" | unit tests | `scripts/shot.sh --test` (exits non-zero on failure) |

The screenshot is a **static shot after launch** — it does not tap, type, or click. Any
behaviour change must be covered by `--test`, not by a screenshot.

## Driving the app to a screen (launch args)

`scripts/shot.sh <name> -- <args>`. Options: `-a` dark, `-d <device>` simulator,
`-w <sec>` wait before shot. Args are read by `Shared/DebugLaunch.swift` (DEBUG only).

| Screen | launch args |
|--------|-------------|
| Expenses home | `-seedSampleData -startTab expenses` |
| Expenses empty | `-startTab expenses` (no seed) |
| Insights | `-seedSampleData -startTab insights` |
| Manage | `-seedSampleData -startTab manage` |
| People leaderboard | `-seedSampleData -startScreen leaderboard` |
| Manage → categories / people / accounts | `-seedSampleData -startScreen categories\|people\|accounts` |
| Expense editor | `-seedSampleData -startScreen editor` |
| Category / People / Account picker | `-seedSampleData -startScreen picker-category\|picker-people\|picker-account` |
| Transaction settings | `-seedSampleData -startScreen settings` |
| Name-duplicate prompt | `-seedSampleData -startScreen name-duplicate` |
| Category / Account color+icon editor | `-seedSampleData -startScreen category-editor\|account-editor` |

Example: `scripts/shot.sh editor-dark -a -- -seedSampleData -startScreen editor`

**Routing (for reference):** `-startTab` and the tab-hosted `-startScreen` values
(`leaderboard`, `categories`, `people`, `accounts`) select a tab so its own deep-link fires;
the rest are presented by `DebugHarness` via a `fullScreenCover`. See `RootView.swift`.

## Reaching a NEW screen the args can't hit yet

If your feature has a screen the table above can't reach, **extend the control surface** —
it's a few lines, and it's the normal way to make a screen screenshot-able:

1. Add the value to the `-startScreen` doc-comment in `Shared/DebugLaunch.swift`.
2. Add a `case "<your-screen>":` to the switch in `Shared/DebugHarness.swift` that builds it.
3. If it's a `fullScreenCover` screen (editor/picker family), add the value to
   `RootView.debugScreens`. Tab-hosted screens instead need their owning tab selected in
   `RootView`'s `startScreen` switch.
4. Add fixture data to `DebugLaunch.seedIfNeeded` if the screen needs it — keep an edge case.

All of the above is `#if DEBUG`; none of it ships in release.

## Guardrails (full list in spec.md — do NOT break)

Style/layout only: no model, query, or logic changes. Keep the 3-tab structure, the
pay-cycle spending-only model, required-field save logic, an empty state per list,
iPad/Mac split, the vocabulary, and dark mode / Dynamic Type / VoiceOver. Money is IDR
whole numbers, right-aligned, monospaced. Accent coral is reserved (see spec).

## State / continuity

Work lives on branch **`revamp/warm-cards`**, one commit per ticket. Tickets 01–08 are
done. Cross-session status is recorded in the user's memory note
`expenseku-revamp-harness.md`. SourceKit may show spurious "Cannot find Theme/Metric/Expense
in scope" cross-file errors — ignore them; `xcodebuild` compiles fine (one module).

## Environment knobs

`SHOT_DEVICE` (default `iPhone 17 Pro`), `SHOT_BUNDLE_ID` (default `randyefan.ExpenseKu`).
DerivedData is local to the checkout (`.scratch/revamp/DerivedData`), so parallel agents in
separate worktrees can each target their own simulator without colliding.
