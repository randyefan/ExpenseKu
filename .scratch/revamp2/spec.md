# ExpenseKu — "Warm Cards II" motion + density revamp

Successor to `.scratch/revamp/spec.md` (the Warm Cards reskin, now merged to `main`).
That pass fixed the *palette*. This one fixes the *surface* and the *motion*.

## What research said

Studied via the Appllama MCP: Fleur (4.8★, $60K/mo), Buddy (4.71★, 104 screens),
TravelSpend (4.81★), Copilot, Monarch.

| Source | Pattern adopted |
|---|---|
| **Buddy** — Daily Transactions | **One card per day**, rows nested inside it, day title joined to the day total by a **dotted leader line**. Kills the "every row is a lonely island" scatter. |
| **Buddy** — Overview | Month pager as a self-contained rounded pill card. |
| **TravelSpend** — Stats | Charts carry **value callouts**, not bare bars. Bold section titles at title size. |
| **Fleur** — everything | Personality comes from **one distinctive motif** used consistently (their script headings + dashed rules), not from many decorations. Ours is the **dotted leader + coral hairline underline**. |

Pattern adopted, never pixels: no pink, no script face, no watercolor. ExpenseKu keeps
Plus Jakarta Sans, cream, and the single coral accent.

## Diagnosis of the current build (verified in the simulator, not assumed)

1. **3 animation call sites in 6,381 lines.** Tab switches, cycle paging, lens
   switches, row taps, totals changing, chart appearance — every one is a hard cut.
2. **Card-per-row scatter.** A day with one expense costs ~320pt of screen. Content
   fills the top third; the rest is empty cream.
3. **Chip rows clip mid-chip** at the screen edge (Insights, leaderboard) — reads as
   a layout bug, not as "this scrolls".
4. **Charts are lifeless**: flat grey bars, no values, current period not marked.
5. **The accent is spent on the wrong thing.** The cycle total renders coral, which
   breaks the token rule ("calm charcoal money totals, NOT red") and stops the accent
   from meaning "this is the action".
6. Empty state is a generic grey circle.

## Guardrails (unchanged from the original brief — do not violate)

- No income, balance, budget, or net anywhere. Spending only.
- Pay-cycle model (ADR-0004) and the 3-tab structure stay.
- One accent: coral `#E8735C`. One grey family (warm). Radius scale: cards 16,
  controls/pills capsule, inner rows 12.
- Plus Jakarta Sans throughout; amounts bold + tabular.
- No emoji in chrome. No gradients. No glassmorphism beyond the system tab bar.

## Motion doctrine

The frequency gate decides everything:

| Frequency | Treatment |
|---|---|
| 100+/day — tab switch, scroll, keyboard | **Platform default. Zero custom code.** |
| Tens/day — row press, chip tap, keypad | Imperceptible: ≤150 ms, scale 0.97 / bg highlight |
| Occasional — cycle paging, lens switch, sheets | Standard spatial motion, 250–400 ms spring |
| Rare — first paint of a screen, total changing | Reveal + numeric roll |

- One vocabulary, defined once in `DesignSystem/Motion.swift`. No ad-hoc
  `.animation(.easeInOut(duration: 0.3))` at call sites.
- **Data the user is reading never moves for style.** The total rolls only when the
  underlying value actually changes (paging, filtering) — never on first paint.
- **Reduce Motion collapses every spatial move to a cross-fade.** Enforced centrally
  by the `.motion(_:value:)` modifier, not remembered per call site.
- Haptics are punctuation: selection tick on lens/chip/cycle change, success on save.
  Never on scroll, never in a loop.

## Tickets

- **01** Motion foundation: `Motion.swift`, press styles, numeric-roll `MoneyText`,
  edge-fade chip rail, dotted leader rule.
- **02** Expenses home: day ledger cards, directional cycle paging, staggered reveal,
  accent correction on the hero total.
- **03** Lens toggle + calendar: matched-geometry pill, cross-fade lenses, day selection.
- **04** Editor: keypad press feedback, amount hero, save/delete confirmation motion.
- **05** Insights: chart grow-on-appear, value callouts, chip rail fades, filter re-runs.
- **06** People leaderboard + person detail: ranked rows with proportion bars.
- **07** Manage + pickers + empty states.
- **08** Full-motion pass: screen-record every flow, dark mode, Dynamic Type XL, tests.

## Verify

Per ticket: build → launch → screenshot light **and** dark → compare → refine.
Screenshots prove layout only. Motion is proved by `xcrun simctl io booted recordVideo`,
watched once for feel and once frame by frame.

### Harness gotcha (cost 3 rounds this session)

`xcrun simctl terminate` + `launch` **inside one shell loop** silently drops the launch
arguments — every screen comes out as the Expenses home. It is not `while read`
(the known trap) and `sleep` between them does not fix it. One launch per Bash
invocation is the only reliable form. Verify by file size before reading a shot.
