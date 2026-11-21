# ExpenseKu tour — handoff after session B

## Approved

21 Nov 2026: the owner approved the Wonder design of Flow AO at the design gate with every
call as drawn (decisions 28–37 in `docs/prd/welcome-tour.md` §8). The PRD now reads
`Status: Accepted`, `Design: Wonder`.

## Next

Stage 6 (build and verify), then 7 (ship the design: keep Flow AO on page 05, end the header
title with "— built", sync frames with fixes) and 8 (merge). Branch `feature/welcome-tour`
from the current `main` (it does not exist yet). The PRD and `.scratch/welcome-tour/` are still
untracked on `main`; commit them on the branch.

## Artifacts

- PRD: `docs/prd/welcome-tour.md` (rules, §5 sample with every row, decisions 1–37, frames).
- Wonder file "ExpenseKu" `01a1baed-bacf-7680-9996-4696474c5186`, page 05
  `f0d8de99-b82d-52a9-8afb-f953d5533f8c`, Flow AO header `des`. Every frame and caption id is
  in `.scratch/welcome-tour/wonder.json`.
- Pose sources (vector SVG artboards): Waving `eon`, Talking `ooo`, Pointing `loc`, Happy
  `lai`, Confused `ide` (row beside AO23). Read their markup with `get_element_code` and ship
  them as vector assets (SVG in the asset catalog, "Preserve Vector Data"); the Waving
  reference PNG is in `.scratch/welcome-tour/poses/`.
- Review: `.scratch/welcome-tour/review.html` + one PNG per frame (AO01…AO23 with b/c moments).

## Cautions for the build

- The guide unit is one view (wallet + bubble); the bubble footer holds segments and Skip.
  It picks the side away from the target and flips (mirrored Pointing) when the target is on
  the left. There is no bottom bar.
- Readouts that stay lit above the scrim (1.2 amount, 2.3 results) are a second, ringless
  hole in the mask, not a copy of the view.
- 1.5 needs the editor form scrolled so the Account row clears the keypad; 4.2 needs the
  Category detail scrolled to today's Rp 45.000 row; 1.6's target is the keypad ✓.
- 1.7: Read receipt is in the editor toolbar and normally opens a Camera/Photos menu; the
  tour bypasses the menu and feeds the bundled image and a prepared reading (no Gemma/OCR).
- Insights' Category "chart" is the SPEND BY CATEGORY bar list; target the Makan row.
- Check in code: the leaderboard's default period (designs assume All time), that search
  spans all cycles (Oct sample has no "kopi"), and that Me is the editor's default person.
- Earlier cautions still stand: hit-test mask with a cut-out (not `allowsHitTesting(false)` on
  everything), `onGeometryChange` target registry (not anchor preferences), tour-owned
  in-memory `ModelContainer` rebuilt per chapter start, KVS outcome beside payday, auto-open
  also counts user Expenses, DEBUG `-welcomeTour <chapter>:<mission>` launch args because the
  Device panel cannot tap.
- Simulator: "iPhone 18 Pro" on the 27.2 runtime; `SHOT_DEVICE`/`-d "iPhone 18 Pro"`.

## Undone

Stages 6–8.
