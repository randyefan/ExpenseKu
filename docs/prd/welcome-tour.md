# PRD — ExpenseKu tour

Status: Built
Date: 2026-11-21
Owner: Randy Efan

Design: Wonder

Companion documents: `CONTEXT.md` (ubiquitous language), `docs/prd/plan-guide.md` and
`docs/prd/plan-guide-visual.md` (the Plan guide this tour hands Plan's detail to),
`docs/prd/quick-entry-form.md`, `docs/prd/receipt-reading.md`, `docs/prd/insights-drill-in.md`,
and the Wonder file **ExpenseKu**, page `05 · Proposals — not built`, **Flow AO · ExpenseKu
tour**. Frame references appear inline as `[→ AO2]`.

---

## 1. What this is

A new user opens ExpenseKu to an empty Expenses tab: no Category, no Account, nothing to
look at. The only guided material, the Plan guide, covers Plan alone and cannot be touched.

The **ExpenseKu tour** is a full-screen, hands-on tour of the whole app, opened
automatically the first time. The user plays four short chapters — **Record**, **Browse**,
**Plan**, **Insights** — on the app's **real screens**, fed by a **sample store that belongs
to the tour**, and does each step themselves: types an amount, picks a Category, pages a
cycle, taps a chart. A **wallet mascot**, drawn as illustrated poses and moved by SwiftUI,
guides every step from a speech bubble. Nothing the tour does reaches the user's data.

## 2. Goals

1. Let a new user do the core actions once, with their own fingers, before meeting an empty app.
2. Show that one expense travels: logged in Record, found in Browse, counted in Plan, charted in Insights.
3. Make the tour memorable: a mascot with reactions, motion and haptics, unlike any other screen in the app.
4. Stay out of the way: one tap to skip, never auto-opened for someone who already has data.

## 3. Non-goals

- **Setting up the user's data.** No starter Categories, Accounts or payday are written; the
  tour ends on the real, empty app (decision 19).
- **Teaching Plan in depth.** Chapter 3 is one mission plus three spotlights and points to the
  Plan guide, which stays unchanged.
- **Manage, Groups, People editing, filters, Select, Paid early, Set aside.** Not in any chapter.
- **Running Gemma or OCR.** The receipt mission plays a prepared reading.
- **Free exploration.** Only the active target responds (§4.4).
- **Changes to the Plan guide**, its invitation card or the Plan options menu.

---

## 4. Rules

### 4.1 When the tour opens

| Situation | Result |
|---|---|
| Launch; KVS has no tour outcome; the user store has **no Expense** | Opens automatically on the opening screen `[→ AO1]` |
| Launch; KVS has no outcome; a chapter was started on this device and not finished | Opens automatically at the **start of that chapter** `[→ AO2, AO11]` |
| Launch; KVS outcome is Finished or Skipped | Never opens by itself |
| Launch; the user store has at least one Expense | Never opens by itself, whatever KVS says |
| Ephemeral store banner showing (store failed to open) | Never opens by itself |
| Manage card or row | Opens the chapter map `[→ AO22]` |

The **outcome** (Finished or Skipped) lives in `NSUbiquitousKeyValueStore`, beside payday, so
a second device that has not synced its Expenses yet does not replay the tour. **Chapter
progress** is local to the device (`UserDefaults`).

### 4.2 Structure

| Part | Content | Frames |
|---|---|---|
| Opening | Wallet drops in, bounces, waves. Title "Meet ExpenseKu", lead "A short tour you play with your own fingers, on sample data. Nothing touches your expenses.", "4 chapters · about 3 minutes · sample data", four numbered chapter tiles. **Start** (primary), **Skip** (plain) | `AO1` |
| 1 · Record | 7 missions (§4.5) | `AO2–AO10` |
| 2 · Browse | 3 missions | `AO11–AO13` |
| 3 · Plan | 1 mission + 3 spotlights | `AO14–AO15` |
| 4 · Insights | 3 missions | `AO16–AO18` |
| Closing | Waving wallet under coin confetti, "You are ready", "That was sample data. Your ExpenseKu starts empty, ready for your first real expense.", four ticked chapter tiles; **Start using ExpenseKu** | `AO19` |

Between chapters a **chapter card** ("Chapter 1 done", the chapter's name, a one-line recap,
four segments, "Next · Chapter 2" and the next chapter's name) plays a coin shower over a
deeper scrim and continues on a tap anywhere. `[→ AO10]` There is no separate bottom bar: the
**bubble's footer** carries four progress segments (one per chapter, the current one filling
per mission) and **Skip**, so they move with the bubble and never cover a target such as the
keypad, Save or the tab bar. `[→ AO2]`

On the first run the chapters play in order. From the chapter map, tapping chapter N plays
N through 4 and the closing; **Start from the beginning** plays the opening onwards. `[→ AO22]`

### 4.3 A mission

The tour shows the real screen full size, built from the sample store. Everything except
the **target** sits under a black scrim at 72%; the target sits in a lit cut-out with an amber
ring and a soft pulse ring. The wallet and its speech bubble form one **guide unit** that
floats on the side away from the target, never covering it; when the target is on the left the
unit flips and the Pointing wallet is mirrored. `[→ AO2–AO18, AO4]`

The bubble is light (`tour-bubble` #F2F3F5, dark text) on the dark scrim, with a small tail
toward the target, and reads top to bottom: an eyebrow ("CHAPTER 1 · RECORD"), the line, and
the footer (segments + Skip). Where a mission's result is the point, that readout stays lit
above the scrim without a ring: the amount in 1.2 and the results in 2.3. `[→ AO3, AO13]`

| Element | Rule |
|---|---|
| Target | One control or region per mission; the only thing that responds to touch |
| Bubble | One or two short sentences in the app's neutral voice (§4.8); no mascot name |
| Wallet | One of five poses (§4.6), positioned beside the bubble |
| Success | When the user completes the target's action, the mission completes on its own; no Next button |
| Spotlight (chapter 3 only) | Not an action: Talking wallet, a ring without pulse, the bubble carries **Next** (**Done** on the last), and the target does not respond `[→ AO15]` |
| Completion moment | Where the result lands elsewhere (1.6, 1.7, 4.2, 4.3) the tour lights it, switches to Happy and shows a short result line before moving on `[→ AO7b, AO17b, AO18b]` |

### 4.4 Touching the wrong thing

Only the target responds. A touch anywhere else in the screen:

1. switches the wallet to **Confused**, with a short head shake and a warning haptic (a touch
   ring marks where the finger landed);
2. replaces the bubble with the mission's shorter **nudge** line;
3. pulses the target twice.

The bubble returns to the full line on the next mission. `[→ AO9]`

### 4.5 Chapters and missions

Sample data is §5. "↗" means the next mission starts on the screen this one leaves.

| # | Screen | Target | User does | Bubble (en) | Frame |
|---|---|---|---|---|---|
| 1.1 | Expenses, List | toolbar + | Tap | Tap + to record what you spent. | AO2 |
| 1.2 | Expense editor | keypad | Type 30.000 + 15.000 and see Rp 45.000 | Type 30000 + 15000. The keypad adds it up. | AO3 |
| 1.3 | ↗ | Category grid | Pick Makan | Every expense has a Category. Pick Makan. | AO4 |
| 1.4 | ↗ | People rail | Add Ibu | Who was it with, or for? Add Ibu. | AO5 |
| 1.5 | ↗ | Account row | Pick Jago | Which Account paid? Pick Jago. | AO6 |
| 1.6 | ↗ | Save (keypad ✓) | Save; the row lands in today's group | Save it. · then: Saved. It is in today's group. | AO7, AO7b |
| 1.7 | Expense editor (opened fresh by the tour) | Read receipt button | Tap; the prepared reading plays; tap Save | A receipt fills the form for you. It is read on this iPhone. · while reading: Watch the amount, Category and note fill in. · then: Check it, then save. | AO8, AO8b, AO8c |
| 2.1 | Expenses, List | cycle ‹ | Page to October 2026 | Each cycle runs from payday to payday. Tap ‹ for the last one. · on October: This is the last one, October. Tap › to come back. | AO11, AO11b |
| 2.2 | ↗ | lens switch | Back with ›, then choose Month | Month shows the same cycle as a calendar. | AO12 |
| 2.3 | ↗ | Search | Type "kopi" | Search finds any expense by its note. | AO13 |
| 3.1 | ↗ | lens switch | Choose Plan | Plan splits income before you spend it. | AO14 |
| 3.2 | Plan | Gaji line | Next | Gaji is the income this cycle expects. | AO15 |
| 3.3 | ↗ | Harian envelope | Next | Harian already counts the Makan you recorded. | AO15 |
| 3.4 | ↗ | Remaining | Next | Remaining is what is left after the plan. The Plan guide shows the rest. | AO15 |
| 4.1 | Tab bar | Insights tab | Tap; the charts grow | Insights turns expenses into charts. | AO16 |
| 4.2 | Insights | Makan in the Category chart | Tap; Makan's detail opens, the tour scrolls to today and lights the Rp 45.000 row | Tap Makan to see what is inside. · then: There is the Rp 45.000 you recorded. | AO17, AO17b |
| 4.3 | ↗ back to Insights | People leaderboard card | Tap; Ibu ranks first | See who the money goes with. · then: Ibu ranks first. Insights is all yours. | AO18, AO18b |

Bubble wording may be shortened during the build; the target and the action may not.

**1.7, the receipt.** Read receipt lives in the expense editor, not on the List, so after
1.6 the tour opens a fresh editor itself and lights its receipt button. Tapping it skips the
Camera / Photos menu. The receipt sample is an image bundled with the app (KOPI SUSU SENJA,
Kopi susu 28.000 + Extra shot 4.000, TOTAL 32.000). The real `ReadingReceiptOverlay` shows
while an amber scan line sweeps the image;
then the amount, Category and note fly one at a time from the receipt into the real form.
The user taps Save and the row lands with its **To check** tag. No model is loaded.
`[→ AO8]`

**3.4** ends chapter 3 with the bubble's tail on Plan's options button (•••, shown with a
dashed amber ring above the scrim), where the Plan guide lives; it does not open it.
`[→ AO15c]`

### 4.6 The wallet

A small illustrated wallet, unnamed, in the app's amber on Ink: a flat bifold wallet with a
dark-amber flap, a cream card peeking out, two eyes, stubby arms and legs, one dark outline
(#14161A). Five poses were generated in Wonder as vectors and ship as transparent assets
(the app is locked to dark); Pointing is mirrored in SwiftUI rather than stored twice:

| Pose | Used for |
|---|---|
| **Waving** | Opening, closing |
| **Talking** | Every bubble with no target, chapter 3 spotlights |
| **Pointing** | Every mission with a target; mirrored when the target is on the other side |
| **Happy** | Mission complete, chapter card |
| **Confused** | Wrong touch (§4.4), Skip confirmation (§4.7) |

`[→ AO23]`

**Motion** (all SwiftUI over the pose images):

| Moment | Motion | Haptic |
|---|---|---|
| Moving to the next target | Arcing hop to the new side; squash on landing | light impact on landing |
| Talking | Small rhythmic sway while the bubble types in | — |
| Mission complete | Happy pose; three to five amber coins pop out and fall into the progress segment | success |
| Wrong touch | Confused pose, head shake | warning |
| Chapter card | Happy pose under a coin shower | success |
| Opening | Drop from above, bounce, then Waving | light impact on landing |

**Reduce Motion:** the hop becomes a crossfade between positions, with no squash, sway, coins or
shower; poses still change. Haptics stay.

### 4.7 Skip and leaving

| Action | Result |
|---|---|
| Skip on the opening screen | Ends the tour, outcome Skipped, no confirmation `[→ AO1]` |
| Skip in the bubble | Full scrim; the wallet turns Confused and asks "Skip the tour? You can open it again from Manage." **Skip** (outlined) / **Keep going** (primary) `[→ AO20]` |
| Skip confirmed | Outcome Skipped; the sample screen fades to the real app |
| App killed mid-chapter | Next launch reopens at the start of that chapter (§4.1) |
| Start using ExpenseKu (closing) | Outcome Finished; the sample fades to the real app; on a replay, back to Manage |

### 4.8 Words

The wallet speaks in the app's neutral voice: no "aku/kamu" in Indonesian, no slang, no
name for itself. Domain words follow the app's labels in each language (Envelope "Pos
anggaran", Remaining "Sisa"). The feature is **"ExpenseKu tour"** in English and **"Tur
ExpenseKu"** in Indonesian. Every string is a symbol key in `Localizable.xcstrings`, in both
languages.

### 4.9 Manage

| Outcome | Entry |
|---|---|
| None or Skipped | A **wallet card** with an amber border above Manage's first section: Waving pose, "ExpenseKu tour", "N of 4 chapters done", four segments, **Open** `[→ AO21]` |
| Finished | The card is gone; a plain **ExpenseKu tour** row ("Play any chapter again", wallet glyph) is its own last section, after Language `[→ AO21b]` |

Both open the **chapter map**, a large sheet with **Close**: Waving wallet, "N of 4 chapters
done", "Pick a chapter. It plays on to the end of the tour.", four chapter rows (a tick or the
number, the name, a one-line detail, a chevron), "Sample data only. Your expenses stay as they
are.", and an outlined **Start from the beginning**. `[→ AO22]`

### 4.10 Accessibility

- VoiceOver reads the bubble when it changes, then moves focus to the target. The wallet is
  one element labelled with its pose ("Wallet, pointing").
- The dimmed screen is hidden from VoiceOver except the target.
- Bubbles grow with Dynamic Type and never truncate; at the largest sizes the wallet shrinks
  before the bubble does.
- Skip, Next and the bubble stay inside the safe area; Skip, Next and Keep going are 44 pt targets.

---

## 5. Sample data

Built fresh into the tour's own in-memory `ModelContainer`, **relative to today** with
**payday 25**. The examples below assume today is Saturday 21 November 2026: the current cycle
is **November 2026** (25 Oct – 24 Nov), the last one **October 2026** (25 Sep – 24 Oct).

| Entity | Values |
|---|---|
| People | Me, Ibu, Rina |
| Accounts | Jago, Mandiri, Cash |
| Categories | Makan, Transport, Belanja, Hiburan, Kos |
| Expenses, this cycle | Kos Rp 2.200.000 (25 Oct, Mandiri, from the plan, no person) and 12 over 8–21 Nov: Sat 21 Nasi padang Makan 38.000 Ibu Jago · Fri 20 Kopi susu Makan 28.000 Rina Cash, Gojek ke kantor Transport 24.500 Me Jago · Thu 19 Indomaret Belanja 186.400 Ibu Mandiri · Wed 18 Bakso Makan 52.000 Ibu Jago · Mon 16 Bioskop Hiburan 75.000 Rina Jago · Sun 15 Makan malam keluarga Makan 120.000 Ibu Mandiri · Fri 13 KRL Transport 18.000 Me Cash · Thu 12 Sabun, tisu Belanja 64.900 Me Mandiri · Tue 10 Ayam geprek Makan 45.500 Rina Jago · Mon 9 Bensin Transport 150.000 Me Cash · Sun 8 Sate Makan 96.000 Ibu Jago. Total Rp 3.098.300 (Outside plan 326.300, From plan 2.772.000) |
| Expenses, last cycle | 8, no plan, total Rp 2.871.200: Kos 2.200.000 (25 Sep), Bensin 150.000 Me Cash (20 Oct), Mie ayam 64.000 Ibu Jago (22 Oct), Superindo Belanja 212.700 Ibu Mandiri (18 Oct), Bioskop Hiburan 100.000 Rina Jago (14 Oct), Martabak Makan 58.000 Rina (11 Oct), Grab Transport 36.500 Me (6 Oct), Pulsa Belanja 50.000 Me (2 Oct). No note contains "kopi" |
| Cycle plan, this cycle | Gaji Rp 8.000.000; Kos Fixed Rp 2.200.000 on Mandiri; Harian Envelope (Makan, Transport) Rp 1.800.000 on Jago; Remaining Rp 4.000.000 |
| Added in chapter 1 | Rp 45.000 Makan, Me + Ibu (Me is the editor's default chip), Jago, today (1.1–1.6); the receipt's Rp 32.000 Makan "Kopi susu", Me, Jago, today, To check (1.7) |

After chapter 1: total Rp 3.175.300 (From plan 2.849.000); Harian spent Rp 649.000 of 1.800.000
(Rp 1.151.000 left); search "kopi" finds two (Rp 60.000); Categories this cycle Kos 2.200.000,
Makan 456.500 (8 expenses, 14%; Jago 308.500, Mandiri 120.000, Cash 28.000), Belanja 251.300,
Transport 192.500, Hiburan 75.000 — Kos is the largest Category, Makan the largest everyday
one; the leaderboard (All time) ranks Ibu Rp 814.100 (8), Me Rp 570.900 (9), Rina Rp 306.500
(5). The editor's quick tiles read Makan, Transport, Belanja, Hiburan, Kos, All…; its People
rail Me, Ibu, Rina, All….

A chapter started fresh or from the map rebuilds the sample as it stands at that chapter's
start: chapters 2–4 already hold chapter 1's two expenses.

---

## 6. Lifetime

| Event | Result |
|---|---|
| Mission complete | Progress segment advances; local progress saved |
| Chapter complete | Chapter card; chapter marked done locally |
| App killed mid-chapter | Resume at that chapter's start, sample rebuilt to match |
| Skip confirmed / opening Skip | KVS outcome Skipped; no auto-open again |
| Closing finished | KVS outcome Finished; Manage shows the row instead of the card |
| Replay from the map | Plays from the chosen chapter to the closing; finishing sets Finished; leaving keeps the earlier outcome |
| User adds their first real Expense while outcome is none | No auto-open from then on; the Manage card stays |
| Second device, KVS synced | Follows the synced outcome |
| Fresh install, iCloud KVS empty, no Expenses | Opens |

## 7. Unaffected

| Behaviour | Stays as |
|---|---|
| The user's store | Never read by the tour except to count Expenses for §4.1; never written |
| Plan guide, its card, the Plan options menu | `plan-guide.md`, `plan-guide-visual.md` |
| Payday, language, filters, sort, notices | Unchanged; the sample uses its own payday 25 |
| Receipt inbox, Gemma download | Untouched; the receipt mission loads no model |
| Schema | No change |

---

## 8. Decision log

Settled in a grilling session on 2026-11-21.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Design track Wonder | — |
| 2 | A **sandbox of missions** on real components with a tour-owned sample store, not coach marks over the user's app | AO2–AO18 |
| 3 | Four chapters: Record, Browse, Plan (light), Insights; Manage left out | AO1 |
| 4 | Opens automatically the first time; reopened from Manage | AO1, AO21 |
| 5 | Linear on the first run; a chapter map when reopened | AO22 |
| 6 | Signature: a **guide mascot** — *owner override*, against a "money thread" following one expense through the app | AO23 |
| 7 | The mascot is a **wallet** — *owner override*, against an amber coin | AO23 |
| 8 | **Illustrated poses moved by SwiftUI** — *owner override*, against a pure SwiftUI-drawn mascot | AO23 |
| 9 | Five poses: Waving, Talking, Pointing, Happy, Confused | AO23 |
| 10 | The wallet has **no name** — *owner override*, against "Ku" | — |
| 11 | Full-size real screen, dimmed outside the target, wallet and bubble beside it | AO2 |
| 12 | Only the target responds; a wrong touch confuses the wallet and repeats a nudge | AO9 |
| 13 | Chapter 1: + · 30.000+15.000 · Makan · Ibu · Jago · Save · Read receipt | AO2–AO8 |
| 14 | Chapter 2: three missions (‹ ›, Month, Search) — *owner override*, against five with Filter | AO11–AO13 |
| 15 | Chapter 3: one mission plus spotlights, then a pointer to the Plan guide — *owner override*, against three missions | AO14–AO15 |
| 16 | Chapter 4: Insights tab · Makan detail · leaderboard | AO16–AO18 |
| 17 | Opening: wallet drops and waves; Start / Skip | AO1 |
| 18 | Full motion set plus haptics — *owner override*, against the motion set without haptics | AO2, AO10 |
| 19 | Closing celebrates, then the real empty app; nothing written | AO19 |
| 20 | Killed mid-tour: reopen at the chapter's start | — |
| 21 | Skip confirms through the Confused wallet; no auto-open afterwards | AO20 |
| 22 | Manage: a **wallet card** until finished, then a plain row at the bottom — *owner override*, against a top row | AO21 |
| 23 | Neutral voice like the app — *owner override*, against a casual "aku-kamu" voice | all |
| 24 | Sample relative to today, payday 25 | AO11 |
| 25 | Outcome in iCloud KVS, auto-open also requires no Expense; chapter progress local | — |
| 26 | From the map, chapter N plays through to the closing — *owner override*, against that chapter only | AO22 |
| 27 | Named "ExpenseKu tour" / "Tur ExpenseKu"; slug `welcome-tour`; its own PRD | AO21 |

Design gate, 2026-11-21 — the owner approved every call below as drawn:

| # | Decision | Drawn in |
|---|---|---|
| 28 | No bottom bar: progress segments and Skip live in the bubble footer, which always sits away from the target | AO2 |
| 29 | Light bubble with eyebrow and tail on a 72% black scrim; five `tour-*` tokens | AO2 |
| 30 | A result readout stays lit above the scrim without a ring (1.2 amount, 2.3 results) | AO3, AO13 |
| 31 | 1.7 runs in a fresh editor the tour opens; the receipt button skips the source menu; two extra lines during and after the reading | AO8–AO8c |
| 32 | Completion moments light the landed result with Happy and a result line | AO7b, AO17b, AO18b |
| 33 | 2.1's line names the action; October gets its own line and › back | AO11, AO11b |
| 34 | Chapter 3 spotlights: Talking, Next, Done on the last, tail on a dashed ••• | AO15–AO15c |
| 35 | Sample fixed as §5: Kos is the largest Category; Me stays on beside Ibu; leaderboard All time | all |
| 36 | Opening and closing words, Keep going primary, Manage row as its own last section, chapter map as a sheet with Close | AO1, AO19–AO22 |
| 37 | Poses are generated vectors of one wallet; Pointing mirrored in code | AO23 |

**Defaults taken without asking** (open to the design gate, all kept): Reduce Motion degrades to
crossfades with haptics kept; the receipt mission ends with Save and a To check row; the
Plan guide card never shows in the sample; four progress segments (now in the bubble footer, decision 28); poses
generated in Wonder and exported as transparent assets; iPad uses the same layout; Skip on
the opening screen needs no confirmation; the ephemeral store never auto-opens the tour.

---

## 8a. Closed during implementation

Built on `feature/welcome-tour`, 2026-11-21. Code: `Features/Tour/` (derivation in
`Features/Tour/Derivation/`, sample in `Features/Tour/Sample/`, views in `Features/Tour/Views/`);
tests: `ExpenseKuTests/WelcomeTourTests.swift`.

| # | Gap | Answer |
|---|---|---|
| C1 | SwiftUI reports toolbar items in the bar's own space, and gives no frame for the search field or the tab bar | Those targets (+, search, •••, Read receipt, search field, Insights tab) come from measured positions on iPhone 18 Pro / iOS 27 (`TourSystemChrome`); every other target reports its own frame |
| C2 | On iOS 27 the minimized search expands into the top bar, not above the keyboard as AO13 draws it | 2.3 lights the field in the top bar; the keyboard is above every window and stays unlit |
| C3 | 1.5 was already met: the editor defaults to Jago, the last Account logged by hand | Until 1.5 the tour's editor opens with no Account; 1.7's editor keeps the default (Jago) |
| C4 | 2.3 needs a tap before typing | Two beats: "Search finds any expense by its note." on the search button, then "Type kopi." on the field with the results lit |
| C5 | 1.7 had no result line | "Saved, marked To check until you look at it." over the landed row |
| C6 | The receipt image | Drawn in SwiftUI (`TourReceiptPaper`) and rendered once with `ImageRenderer`; no image file ships |
| C7 | The reading | The real `ReadingReceiptOverlay` shows for 2 s, then the amount, Category and note land one at a time in the form. No scan line and no flight from the receipt: the form itself is what fills |
| C8 | The last mission of a chapter went straight to the card, so 2.3's results barely showed | The last mission holds its result 1.8 s before the chapter card |
| C9 | After 1.7 the List and Plan show the real "1 from receipts to check" banner, which pushes Harian under the tab bar | Kept (it is the app's behaviour); 3.3 scrolls the Plan list to Harian. List ignores `ScrollPosition`, so this one scroll uses `ScrollViewReader` |
| C10 | 4.3's card sits below the fold after returning from Makan | Returning to Insights scrolls it to the bottom; 4.2's detail scrolls today's group to the centre |
| C11 | Paging and lens switches keep the outgoing view reporting while it slides away | The registry keeps every reporter and the newest one still on screen wins |
| C12 | §5's leaderboard lists Me, but the app's leaderboard never ranks Me | The tour shows Ibu Rp 814.100 (8), then Rina Rp 306.500 (5) |
| C13 | The screens read the payday from `Payday.current` | It returns the sample's 25 while a tour runs (`Payday.sampleOverride`); plan maintenance on the user's store reads `Payday.stored` |
| C14 | The iCloud outcome outlives an uninstall | Expected (§4.1). DEBUG `-resetWelcomeTour` forgets it; `-welcomeTour opening|1…4` opens the tour there; screen-driving DEBUG args and XCTest never auto-open it |
| C15 | AO15's eyebrow counts spotlights ("2 OF 3") and §4.6 says the bubble types in | Not built: the eyebrow names the chapter only and a new line crossfades |
| C16 | §4.10 asks VoiceOver to move to the target and hide the dimmed screen | The new line is announced and the wallet reads its pose; the screen under the scrim is not hidden from VoiceOver and focus does not move. Open |

## 9. Design traceability

Wonder **ExpenseKu**, page `05 · Proposals — not built`, **Flow AO · ExpenseKu tour**.

| Frame | Covers |
|---|---|
| **AO1** · Opening | §4.2, §4.7 opening Skip, decision 17 |
| **AO2** · 1.1 Tap + | §4.3 mission anatomy, bubble footer, decision 11, 28 |
| **AO3** · 1.2 Keypad | 1.2 |
| **AO4** · 1.3 Makan | 1.3 |
| **AO5** · 1.4 Ibu | 1.4 |
| **AO6** · 1.5 Jago | 1.5 |
| **AO7** · 1.6 Save, coins | 1.6, §4.6 mission-complete motion |
| **AO8** · 1.7 Read receipt | §4.5 receipt |
| **AO9** · Wrong touch | §4.4 |
| **AO10** · Chapter card | §4.2 chapter card |
| **AO11** · 2.1 Last cycle | 2.1, §5 payday 25 |
| **AO12** · 2.2 Month | 2.2 |
| **AO13** · 2.3 Search "kopi" | 2.3 |
| **AO14** · 3.1 Plan lens | 3.1 |
| **AO15** · 3.2–3.4 Spotlights | chapter 3 spotlights, Plan guide pointer |
| **AO16** · 4.1 Insights | 4.1 |
| **AO17** · 4.2 Makan detail | 4.2 |
| **AO18** · 4.3 Leaderboard | 4.3 |
| **AO19** · Closing | §4.2 closing, decision 19 |
| **AO20** · Skip confirmation | §4.7 |
| **AO21** · Manage card and row | §4.9 |
| **AO22** · Chapter map | §4.9, decision 26 |
| **AO23** · Wallet poses | §4.6 |
| **AO7b** · Row lands, coins | §4.3 completion moment |
| **AO8b**, **AO8c** · Reading, check then save | §4.5 receipt |
| **AO11b** · October | 2.1 |
| **AO15b**, **AO15c** · Harian, Remaining spotlights | 3.3, 3.4 |
| **AO17b** · Makan detail | 4.2 |
| **AO18b** · Ibu first | 4.3 |
| **AO21b** · Manage tour row | §4.9 Finished |

Wonder ids: `.scratch/welcome-tour/wonder.json` (header `des`, one column per frame at
x = 502·(n−1), phones from y 23640, extra moments of a column 1000 px lower).
