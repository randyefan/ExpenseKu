# AGENTS.md — ExpenseKu feature-development harness

**If you are an agent building a new feature, read this file first.** It defines a
**staged, gated pipeline**: you clarify one stage, loop with the user until they *agree*,
and only then advance to the next stage. The user's agreement is the oracle at every gate —
**never skip a gate, never advance on your own.**

- Working directory for all commands: the repo root (`ExpenseTracker/`).
- Reuses the visual/behaviour verify loop from `.scratch/revamp/` — see its `AGENTS.md`
  for `scripts/shot.sh` and `-startScreen` details.
- Adds an **interactive** verify loop on top: `scripts/simdrive.sh` drives the running app
  with real taps + key input (see "Interactive verification" below). Stage 3 is **not**
  done on static screenshots alone — you must run the feature's flow.

## The pipeline

```
0 Brief ──▶ [GATE] ──▶ 1 Wireframe ──▶ [GATE] ──▶ 2 Tech spec ──▶ [GATE] ──▶ 3 Build+verify ──▶ [GATE] ──▶ 4 Ship
              user            (loop until          user            (loop until          user           (loop until         user
             agrees          user agrees)         agrees          user agrees)         agrees         user agrees)        agrees
```

Each stage produces **one artifact file** in the feature folder. A stage is not done until
its gate is passed. If the user changes their mind at a later stage, walk back, update the
earlier artifact, and re-pass its gate.

## Starting a feature

1. Pick a slug, e.g. `recurring-expenses`. Create `.scratch/features/<slug>/` by copying
   `.scratch/features/_template/` into it.
2. Open `STATUS.md`, set the current stage to **0 Brief**.
3. Work stage 0. Then run the gate.

## Running a gate

At the end of every stage:
1. Summarise the stage's artifact in a couple of lines.
2. Ask the user to approve, using the **AskUserQuestion** tool. Offer at least:
   *Approve — advance* / *Revise — I'll give notes*. For wireframes, put each ASCII
   mockup variant in an option `preview` so the user compares side by side.
3. **If not approved:** apply their notes, update the artifact, ask again. Loop here.
   Do not touch the next stage.
4. **If approved:** record it in `STATUS.md` (stage + date + one-line note), then advance.

Treat approval as scoped to *that artifact as written*. A later change invalidates it.

## Stage 0 — Brief  →  `00-brief.md`

Capture, in the user's words: the problem, who it's for, and **acceptance criteria**
(a checklist of observable outcomes). No solution yet. Gate: "Is this the feature?"

## Stage 1 — Wireframe  →  `01-wireframe.md`

Low-fidelity ASCII wireframes for **every screen and state** the feature touches — include
empty, loading, and error states. Annotate what each control does. Stay within the existing
"Warm Cards" language and the 3-tab structure (see `.scratch/revamp/spec.md` guardrails).
Gate: show the wireframes (use AskUserQuestion `preview` per variant) and loop until the
user agrees on the UX. **No code in this stage.**

## Stage 2 — Tech spec  →  `02-tech-spec.md`

How it will be built, concretely:
- **Data model**: new/changed SwiftData models, fields, migrations.
- **Files touched**: list them; note new views/components under `DesignSystem/` or a feature
  folder.
- **Control surface**: which `-startScreen` value + `DebugHarness` case you'll add so the new
  screen is screenshot-able (see revamp `AGENTS.md` → "Reaching a NEW screen").
- **Fixtures**: what to add to `DebugLaunch.seedIfNeeded`.
- **Test plan**: the unit tests that will prove the behaviour (this is the behaviour oracle).
- **Interactive flow**: the exact `simdrive.sh` tap/key sequence Stage 3 will run to verify
  behaviour in the app (launch args → taps → expected state at each step). This is required.
- **Risks / guardrails touched**: call out anything near the revamp guardrails.
Gate: user agrees the approach is sound before any code is written.

## Stage 3 — Build + verify  →  update `STATUS.md` as you go

Now write code, driven by **three** oracles:
- **Behaviour (unit):** write the tests from the spec first, then implement until
  `scripts/shot.sh --test` is green.
- **Visual:** add the control-surface hook, then `scripts/shot.sh <slug>` (and `-a` for dark),
  Read the PNG, refine until it matches the approved wireframe.
- **Interactive (always):** drive the real flow with `scripts/simdrive.sh` — tap, type, and
  key through every interaction the feature adds, capturing a before/after screenshot at each
  step and Reading them to confirm the app *behaved*. A static shot proves how a screen
  *looks*, never how it *responds*; taps have already caught bugs a screenshot could not (a
  keyboard-dismiss guard that silently blocked focus). **Do this for every feature, even a
  "display-only" one:** at minimum drive the taps that reach and exercise the new UI. If the
  behaviour can't be reduced to a unit test, this flow is its only regression evidence — spell
  the exact tap sequence out in `02-tech-spec.md`'s test plan and record its result in
  `STATUS.md`.

Gate: present the unit result **and** the interactive before/after screenshots (the flow, not
just an end-state), then loop on the user's notes until approved.

## Interactive verification — `scripts/simdrive.sh`

`shot.sh` launches and snaps a static picture; it never taps or types. `simdrive.sh` drives
the **booted** Simulator like a user so you can verify behaviour, not just looks.

Setup (once): `brew install cliclick`, and grant Accessibility permission to whatever runs
the script (System Settings → Privacy & Security → Accessibility). It targets the same device
as `shot.sh` (`SHOT_DEVICE`, default "iPhone 17 Pro").

Commands:
```
scripts/simdrive.sh launch [-a] [-- <launch args>]   # relaunch app fresh (e.g. -startScreen editor)
scripts/simdrive.sh shot   <name>                    # screenshot → .scratch/revamp/shots/<name>.png
scripts/simdrive.sh tap    <px> <py>                 # tap at SCREENSHOT-PIXEL coords
scripts/simdrive.sh key    [cmd|shift|option|ctrl …] <k>   # send a key combo
scripts/simdrive.sh bounds                           # print the pixel→screen mapping
```

**Coordinates are screenshot pixels** — the exact numbers you read off a shot (a 1206×2622
PNG). Read a shot, pick the pixel of the thing you want to hit, `tap` it; the script maps
pixel→on-screen from the live window bounds, so you never compute screen coordinates yourself.

The loop: `launch …` → `shot before` → Read before.png → `tap x y` → `shot after` → Read
after.png → compare. Confirm the *state changed as intended* (a row appeared, a sheet opened,
the keyboard dismissed), then move to the next interaction.

Gotchas (learned the hard way):
- **First tap after a `shot` (or after focus left the Simulator) can be swallowed** as window
  re-activation instead of an in-app tap. If a tap seems to do nothing, just issue it again —
  the repeat lands. Don't conclude "broken" from a single no-op tap.
- **Software keyboard hidden?** When a hardware keyboard is "connected," tapping a text field
  focuses it but shows no on-screen keyboard. Reveal it with `scripts/simdrive.sh key cmd k`.
  (Focus still happens without it — watch for the on-screen state change, e.g. a dock hiding.)
- The mapping assumes a ~28pt window title bar; override with `SIM_TITLEBAR` if a run looks
  offset. `simdrive.sh bounds` prints what it computed.
- Shots land in the gitignored `.scratch/revamp/shots/` — they're scratch, not artifacts.

## Stage 4 — Ship

Commit on a feature branch (`feature/<slug>`), one coherent commit or a small logical series.
Summarise what shipped against the stage-0 acceptance criteria. Gate: user confirms done.

## Rules

- **One stage at a time.** Don't wireframe and spec together; don't code before the spec gate.
- **The gate is a hard stop.** Ask, then wait. Silence is not approval.
- **Persist everything to the artifact files**, not just chat — a future session resumes from
  `STATUS.md` + the artifacts, cold.
- **Guardrails still apply**: this app's model, vocabulary, and 3-tab shell are fixed unless
  the brief explicitly changes them and the user approves it at the stage-0 gate.
