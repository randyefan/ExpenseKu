# 10 — Remaining device verification

Status: ready-for-human
Feature: Payday Planning (`docs/prd/payday-planning.md`), merged to `main` at `f3338eb`

Everything here is **implemented and unit-tested** (274 green). What is missing is a
device pass. The core — plan/ledger separation, the arithmetic, materialisation,
carry-over — was driven with idb and is proven; this is the tail.

---

## How to run one

```bash
scripts/shot.sh <name> -a dark -w 8 -- -seedSampleData -seedPlanData normal -startScreen plan
```

Writes `.scratch/revamp/shots/<name>.png`. Everything after `--` is launch arguments.

**Two traps, both of which cost me a cycle:**

- **Uninstall between runs.** The seed only populates an empty store, so a second launch
  silently reuses the first one's data:
  `xcrun simctl uninstall booted randyefan.ExpenseKu`
  It does nothing at all when no device is booted — check `xcrun simctl list devices booted` first.
- **A stale store crashes the app**, and under `xcodebuild test` it presents as
  *"the test runner crashed before establishing connection"*, not as a migration error.
  Same fix: uninstall.

### Launch arguments that exist

| Flag | Values |
|---|---|
| `-seedPlanData` | `normal` · `payday` · `auto-landed` · `overspent` · omit for no plan |
| `-startScreen` | `plan` · `plan-next` · `plan-dormant` · `plan-list` · `groups` · `group-editor` · `category-editor` |

The plan editors have **no** `-startScreen` of their own — reach them by tapping a row.

---

## A. Screens written but never opened on device

- [ ] **I1 · Income line editor**
  `-seedPlanData normal -startScreen plan`, tap the **Gaji Fulltime** row (the name, not
  the tick).
  Pass: amount hero, Name, a "Sudah masuk" toggle, red *Delete income line*. Editing the
  amount must move **Total income** and **Sisa** together.

- [ ] **I2 · Transfer adjustment**
  `-seedPlanData normal -startScreen plan`, scroll to the foot, tap the **ke Mandiri** row.
  Pass: hero labelled ADJUSTMENT showing −Rp 700.000, and three lines reading
  Planned `Rp 2.826.500` / Adjustment `−Rp 700.000` / Transfer `Rp 2.126.500`.
  Flipping to *Transfer more* must make the adjustment positive.

- [ ] **I7 · Delete a plan item**
  Tap any plan row → **Delete plan item**.
  Pass: for an item that has posted, the alert says the expense *"stays in your ledger —
  only the plan item goes"*; for one that has not, *"nothing in your ledger changes"*.
  After deleting a posted item, the expense must still be in the **List** lens.

- [ ] **G1 · Payday morning**
  `-seedPlanData payday -startScreen plan`
  Pass: both income lines ticked, notice reads *"Payday — N transfers to make"*, header
  reads **PLAN · 14 ITEMS · NONE DONE YET**, and there is **no drift strip**.

- [ ] **G4 · Future cycle in List**
  `-seedPlanData normal -startScreen plan-list`, then tap **›**.
  Pass: the existing "No expenses this cycle" empty state, unchanged, and the **›** arrow
  still enabled. Repeat in **Month**.

---

## B. Not exercised at all

- [ ] **iPad.** Never launched once. We agreed the Plan lens renders in the split-view
  sidebar as on iPhone, with the detail pane keeping its placeholder — but that is an
  assumption, not an observation. `-d "iPad Pro 11-inch (M5)"`.
  Pass: nothing clipped, the three-segment toggle fits, rollups reachable.

- [ ] **Accessibility text sizes.** My own plan flagged this and I skipped it. Set
  Settings → Accessibility → Larger Text to **AX3** and check, in order of risk:
  1. the **three-segment toggle** — the likeliest break; two segments fit today, three at
     AX3 may not, and the `matchedGeometryEffect` pill will jitter if the `HStack` squeezes
  2. a **plan row's chip line** — plain `HStack`, will truncate rather than wrap
  3. the **cycle header** with a wrapped title

---

## C. Two decisions for you, not bugs

- [ ] **The plan item editor's keypad covers Due day and Auto.**
  Frame **F1** draws that screen with *no* keypad dock; I reused the expense editor's
  sticky one. The controls are reachable by scrolling and behave correctly, so this is a
  design divergence rather than a defect. Options: leave it; make the dock dismissible;
  or drop it and edit the amount another way. Needs your call — I did not want to guess.

- [ ] **`DueDayStepper` exposes no `AXValue`.** VoiceOver announces "Due day" but not
  which day. The `.accessibilityAdjustableAction` works. One-line fix once someone
  confirms how it should read ("Day 20 of the month"?).

---

## Verified already — no need to redo

E1 · E2 · E3 · E4 · E5 · F1 · F2 · F3 · F4 · G2 · G3 · H1 · H2 · H3 · H4 · I3 · I4 · I5 · I6 · I8

Including the round trip that matters: ticking a Rp 2.200.000 item at Rp 2.500.000 moved
SPENDING `1.327.400 → 3.827.400` and drift `95.600 → 395.600` while **Sisa did not move**,
and un-ticking put all three back.

Shots in `.scratch/payday-planning/shots/`.
