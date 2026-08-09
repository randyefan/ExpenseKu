# ExpenseKu visual revamp — harness spec

Reskin every ExpenseKu surface to the approved **"Warm Cards"** direction **without changing
behaviour, flow, navigation, or vocabulary**. Source of truth = the frozen Stitch mockups in
`refs/` (project `3081179521226974825`). See `docs/design-brief.md` for the full brief and
`CONTEXT.md` for the ubiquitous language.

This is a **style/layout** change only. No model, query, or logic changes. Existing tests must
stay green.

## Design tokens ("Warm Cards")

| Token            | Light       | Dark        | Use |
|------------------|-------------|-------------|-----|
| `bg`             | `#FBF7F3`   | `#17130F`   | screen canvas |
| `card`           | `#FFFFFF`   | `#211C1A`   | elevated rows/cards |
| `hairline`       | `#EFE8E1`   | `#2E2825`   | dividers, card borders |
| `text`           | `#2A2320`   | `#F5F0EC`   | primary text + **row amounts** |
| `textSecondary`  | `#8A817C`   | `#A79E98`   | meta lines, section headers |
| `accent` (coral) | `#E8735C`   | `#E8735C`   | + button, active tab, selected state, hero total, chart highlight |

- **Font:** Plus Jakarta Sans throughout. Amounts: weight 700 + `.monospacedDigit()`.
- **Shape:** card radius 16, padding 16, inter-card gap 12. Category chips = muted pastel fills.
- **Accent is reserved** — coral appears only on the + button, the active tab, selected/checked
  states, the hero cycle total, and small chart highlights. Everything else is charcoal/gray.

### ⚠ Open tension to resolve
`docs/design-brief.md` + design memory say "money totals NOT red." The approved `home.png`
mockup renders the **hero cycle SPENDING total in coral**. Current harness decision: **hero
cycle total = coral; all per-row amounts = charcoal (`text`).** Owner may veto → then hero
total also becomes charcoal. Do not make row amounts coral either way.

## Hard guardrails (from the brief — do NOT break)

- Keep the **3-tab** structure (Expenses / Insights / Manage) and every screen + action reachable.
- Keep the **pay-cycle model**: one cycle at a time, end-month title, bounded ‹ › arrows,
  **spending-only** header. Never introduce income / balance / budget / remaining / net.
- Keep **required-field logic** (amount > 0 AND category to save).
- Keep an **empty state for every list**.
- Keep iPhone-push / iPad-Mac-split adaptivity on Expenses.
- Keep vocabulary: Expense · Category · Account (a label, not a balance) · Person/Companion ·
  Uncategorized · Unassigned · Pay cycle / Monthly Start Date · People leaderboard.
- **Dark mode + Dynamic Type + VoiceOver** keep working; never encode meaning in color alone.
- All money is IDR whole numbers, right-aligned, monospaced digits.

## The build + verify loop (per ticket)

1. Read the ticket's ref image(s) in `refs/`.
2. Edit SwiftUI (design tokens + components live in `ExpenseKu/ExpenseKu/DesignSystem/`).
3. Build + screenshot: `scripts/shot.sh <shot-name> [-- <launch args>]` (see script header).
4. Read `shots/<shot-name>.png` and compare against the ref. Refine. Repeat until it matches.
5. Also screenshot **dark mode** (`shot.sh <name>-dark -a` ) and confirm it reads.
6. `xcodebuild test` (or `scripts/shot.sh --test`) — logic must stay green.
7. Commit.

Verify is **visual**: the agent Reads both PNGs and eyeballs layout/spacing/color/hierarchy.
It is not pixel-diffing — sample data and fonts differ from the mockup, so match the *design*,
not the bytes.

## Screens → refs → tickets

| Screen                | ref                     | launch args                                  | ticket |
|-----------------------|-------------------------|----------------------------------------------|--------|
| DesignSystem foundation | (tokens above)        | —                                            | 01 |
| Expenses home         | `home.png`              | `-seedSampleData -startTab expenses`         | 02 |
| Expenses empty state  | `home-empty.png`        | `-startTab expenses` (no seed)               | 02 |
| Expense editor        | `expense-editor.png`    | `-seedSampleData` → open editor              | 03 |
| Category picker       | `picker-category.png`   | via editor                                   | 03 |
| People picker         | `picker-people.png`     | via editor                                   | 03 |
| Name-duplicate prompt | `name-duplicate.png`    | via picker "New"                             | 03 |
| Transaction Settings  | `transaction-settings.png` | via home calendar button                   | 04 |
| Insights              | `insights.png`          | `-seedSampleData -startTab insights`         | 05 |
| People leaderboard    | `leaderboard.png`       | `-seedSampleData -startScreen leaderboard`   | 06 |
| Manage                | `manage.png`            | `-seedSampleData -startTab manage`           | 07 |
| iPad/Mac split        | `desktop-split.png`     | iPad sim, `-seedSampleData`                  | 08 |

Ticket 01 (foundation) blocks all others. Tickets 02–08 are **parallelizable** in worktrees.
Shared-file merge points to expect: `project.pbxproj` (new files + font), `Info.plist`
(`UIAppFonts`), `RootView.swift` (tab bar tint). Land 01 first, then fan out.
