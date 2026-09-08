# revamp4 — the entity Studio (add/edit Category, Account, Person)

## Why
The add/edit screens were a conventional form: small circle preview, name field,
colour rail, icon grid, toolbar Save. Every reference in the category — Buddy's
Edit Categories, Anotar's Create Folder modal — lands on that same skeleton, so
matching it is table stakes, not a design. Naming a category is a *rare,
deliberate* act (motion-law frequency gate: delight is licensed here), and it is
the only screen in ExpenseKu where the owner is making something rather than
recording something. It should feel like a workbench.

## Research (Appllama)
- `936422955` Buddy — Edit Categories (flat rows, no preview at all), Create
  Wallet (**tabbed modal**: SPENDING / SAVING / DEBT across the top).
- `6737702076` Anotar — Create Folder modal: name, colour grid, icon grid,
  Cancel / Create. The exact skeleton ExpenseKu already had.
- `1523682319` Widgetsmith — icon pack browsing: grouped sections beat one flat grid.
Pattern adopted: **tabbed workbench inside a modal** (Buddy) + **grouped,
searchable icon catalogue** (Widgetsmith), with a live subject on top.

## The design
1. **Ambient wash.** The whole sheet background carries the subject's tint as a
   soft top gradient, cross-fading on every colour change. The screen itself is
   part of the preview.
2. **Stage.** A card, not a circle. Two faces, tap to flip in 3D:
   - *mark* — 92pt squircle, glyph/initial, name, caption.
   - *in context* — the row exactly as the app draws it, with a sample amount,
     answering "what will this look like in my ledger?".
   Drag it and it tilts in parallax, springing back on release. A shuffle button
   rolls colour + icon together.
3. **Name.** Underline sweeps to accent on focus (kept), plus a clear button and
   a live suggestion chip when the typed name resolves to a known glyph.
4. **Workbench.** Segmented Colour | Icon, panes swapped with the house
   directional page transition.
   - *Colour*: a continuous **hue dial** — drag anywhere on the spectrum, snap to
     the twelve preset hues with a selection tick, plus quick-pick dots and Auto.
     Colour stops being twelve choices and becomes a dial.
   - *Icon*: search field + eight named groups, ~48 glyphs, filtering animated.
5. **Save** moves out of the toolbar into a tinted pill pinned above the keyboard
   (`safeAreaInset`), wearing the entity's own colour.

## Guardrails
- One accent (amber) for chrome; the entity tint is the subject's own colour, not
  a second accent.
- All motion through `Motion.*` / `.motion(_:value:)`, so Reduce Motion collapses
  it centrally. No tilt, no flip rotation, no page travel under Reduce Motion.
- Only ONE transition on the pane replacement path; direction set before the
  state change (revamp2 lesson).
- No pinned header — everything scrolls (revamp2 lesson).
- Stored value stays an "RRGGBB" hex authored by the palette recipe, so the model,
  `Theme.categoryTint(hex:seed:)` and the existing tests are untouched.
