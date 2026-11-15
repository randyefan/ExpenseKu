# PRD — Plan guide, shown not told

Status: Built
Date: 2026-11-16
Owner: Randy Efan

Design: Wonder **ExpenseKu → 05 · Proposals — not built → Flow AN · Plan guide, shown not told**

Companions: `docs/prd/plan-guide.md` (the guide this revises; Flow AM), `CONTEXT.md`,
and the PRDs of every component a lesson shows (`payday-planning.md`, `partial-transfer.md`,
`set-aside.md`, `envelope-detail.md`, `paid-elsewhere.md`, `look-back.md`, `plan-sort.md`,
`clear-plan.md`). Frame references appear inline as `[→ AN2]`.

---

## 1. What this is

The Plan guide shipped on 15 November 2026 explains Plan in about 1,430 words over
15 lesson steps, roughly 95 words a step. Each step shows a hand-written example card
(names and amounts in a list) followed by two or three paragraphs of rules, many of them
edge cases. The owner's users would rather see the feature than read about it.

This revision keeps the guide's shape (introduction plus six topics, 15 steps, the same
progress) and replaces what a step shows: the **real Plan components**, rendered with the
guide's November sample, with **one spotlight at a time** on the element that matters and a
short caption for it. Edge-case rules leave the guide.

## 2. Goals

1. Show the actual rows, checks, sheets and totals the user will meet in Plan.
2. Cut each step to a heading, a one-sentence lead and one short caption at a time.
3. Show consequences by changing the example's state between spotlights, not by
   describing them.
4. Keep everything `plan-guide.md` promises about entry, progress and no data writes.

## 3. Non-goals

- **Interactive components.** The example cannot be tapped; Next is the only way forward.
- **Edge-case rules.** Adjustment rounds, Undo Done deleting the Expense, notice priority,
  Auto posting regardless of Funded, Set aside never copied forward and similar rules are
  not taught. The app already states them where they apply (confirmations, the Auto review
  sheet, the Clear Plan dialog).
- **Coach marks over the user's own Plan.**
- **Changes to the topic index, the invitation card or the Plan options menu.**
- **Remembering the spotlight** across closing or relaunching.
- **New materials, merged topics or changed step counts.**

---

## 4. Rules

### 4.1 A lesson step

A step shows, top to bottom: the existing lesson header (material, progress segments,
Close), "Step N of N · <step title>", a **heading**, a **one-sentence lead**, the
**example**, and the **spotlight caption**. The footer (Topics/Back, Next/Finish) and the
"Examples only. Your data stays unchanged." line are unchanged. `[→ AN2–AN16]`

| Element | Rule |
|---|---|
| Heading | One line where it fits; the step's idea, not a rule |
| Lead | One sentence, at most about 15 words |
| Example | Real Plan views under the caption-style label "EXAMPLE · NOVEMBER" |
| Caption | The active spotlight's caption only, at most about 15 words, below the example; ●○○ position dots sit above it, the active dot in the accent colour |
| Takeaways | Removed |

### 4.2 The example is the real component

Each step renders the app's own SwiftUI views (table §4.5), fed by the November sample
of `plan-guide.md` §5 held in an **in-memory store that belongs to the guide**. Nothing
reads or writes the user's store. The example ignores every filter, sort and notice the
user has set. `[→ AN2–AN16]`

The example is inert: hit testing is off, so no row, check, menu or button reacts.
`[→ AN2–AN16]`

### 4.3 Spotlights

Each step has two to five **spotlights** in a fixed order. The active spotlight's element
is shown at full strength inside a 2 pt accent ring (radius following the element); the
rest of the example is dimmed to 30 % opacity. The ring's space is reserved on every
spotlightable element, so moving between spotlights never shifts the layout. The caption below the
example belongs to the active spotlight. `[→ AN2–AN16]`

A spotlight may carry its own **snapshot** of the example: the sample in a different state
(Gaji arrived, Kos Funded, Liburan deselected). Moving to that spotlight swaps the
example to its snapshot with a short transition; with Reduce Motion on, a plain
crossfade. `[→ AN3, AN4, AN9–AN15]`

### 4.4 Navigation

| Where | Next | Back / Topics |
|---|---|---|
| Spotlight k of n, k < n | Spotlight k + 1, same step | Spotlight k − 1 (k > 1) |
| Last spotlight, not last step | Next step, spotlight 1 | — |
| Last spotlight, last step | Finish topic / Explore topics, as `plan-guide.md` §4.5 | — |
| Spotlight 1, step > 1 | — | Previous step, **its last spotlight** |
| Spotlight 1, step 1 | — | Topics (back to the index) |

The primary button keeps its current labels: Next while anything is left in the material,
Finish topic or Explore topics on the last spotlight of the last step. The secondary button
reads Back whenever a spotlight or step lies behind, and Topics only on step 1, spotlight 1.
`[→ AN15, AN16]`

Close works at any spotlight, as today. `[→ AN2–AN16]`

### 4.5 Content contract

This section replaces `plan-guide.md` §4.4. The spotlight order and what each one points
at are fixed; wording may be shortened in the build. `↻` marks a spotlight that swaps the
example to a new snapshot; a snapshot holds for the spotlights after it in the same step,
and Back restores the state the earlier spotlight showed. `[→ AN2–AN16]`

| Step | Example shows | Spotlights | Frame |
|---|---|---|---|
| Intro 1 · Before payday | Totals card (Gaji, Total income, Total cost, Remaining), Plan rows Kos / Harian / Liburan · Dec | ① Gaji income line ② the rows card (three kinds) ③ the Remaining line | AN2 |
| Intro 2 · On payday | Totals card, Transfer checklist (Jago, Mandiri), the transfer sheet's Moved to Jago button | ① ↻ Gaji arrived ② the checklist ③ Moved to Jago | AN3 |
| Intro 3 · Through the cycle | Kos and Harian rows (Harian Rp 120.000 spent), a Remaining card | ① ↻ Kos Done ② Harian ③ Remaining | AN4 |
| 1.1 Choose a cycle | Cycle header ‹ November 2026 ›, Gaji line, Add plan item / Add income line / Look back at October | ① cycle header ② Gaji line ③ Add plan item | AN5 |
| 1.2 Reuse | `PlanEmptyState` (No plan yet, Copy from October, Start empty), a Look back row (Harian, Rp 1.800.000 in October, + Add pill) | ① Copy from ② Start empty ③ Look back row | AN6 |
| 2.1 Plan and its items | Kos, Harian, Liburan · Dec rows | ① Kos ② Harian ③ Liburan | AN7 |
| 2.2 Set aside | Totals (income, cost, Remaining), `PlanSetAsideRow` Liburan · Dec | ① the row body (target) ② Remaining ③ its check | AN8 |
| 3.1 Row and status | `PlanFixedRow` Kos | ① the row body ② ↻ check Funded ③ ↻ check Done | AN9 |
| 3.2 Dates and Auto | `PlanFixedRow` Kos with Due 5 and Auto chips, Auto disc | ① Due 5 chip ② ↻ Auto chip, check Auto posted ③ ↻ check Funded | AN10 |
| 4.1 See destinations | Gaji line (arrived), Transfer checklist Jago / Mandiri, Kos row | ① ↻ Gaji arrived ② the checklist ③ ↻ Kos without an Account, Mandiri's line gone, "0 OF 1 SENT" | AN11 |
| 4.2 Move some now | Transfer sheet "Transfer to Jago": TO SEND · 1 OF 2, Harian chosen, Liburan · Dec, Transfer now, Moved to Jago | ① ↻ Liburan deselected ② Transfer now Rp 1.800.000 ③ Moved to Jago ④ ↻ sheet gone: Jago half-filled "1 item in · Rp 1.000.000 to go", Harian with the funded disc | AN12 |
| 5.1 Spend from an Envelope | `PlanEnvelopeRow` Harian (Rp 120.000 spent) with + disc and its open menu; the expense editor for ③ | ① the bar and its line ② + and its menu ③ editor: Rp 45.000 Makan, Envelope = Harian ④ ↻ Harian Rp 165.000 spent ⑤ ↻ Rp 1.950.000 spent, Rp 150.000 over, red | AN13 |
| 5.2 Other Accounts and cycles | PAID ELSEWHERE: CC Danamon Rp 75.000 "Grab · Harian · to move from Jago"; PAID EARLY · DECEMBER: Tiket pesawat Rp 300.000 → Liburan · Dec | ① the CC Danamon row ② ↻ ticked, "Moved from Jago" ③ the paid-early row | AN14 |
| 6.1 Change the view | PLAN header with the sort control, rows Kos / Harian / Liburan · Dec, the open sort menu, SHARE OF INCOME · PLANNED | ① the open menu (six orders) ② ↻ sort Account: JAGO and MANDIRI groups ③ group shares | AN15 |
| 6.2 Notices and clearing | Auto review notice, cycle header December 2026, Plan options menu (Plan guide, Clear Plan) | ① the notice ② Clear Plan | AN16 |

#### Words

| Step | Heading | Lead | Captions |
|---|---|---|---|
| Intro 1 | Plan before the money arrives | Expected income, what each part is for, and what is left. | ① Gaji is the income you expect this cycle. ② Each item is Fixed, an Envelope or Set aside. ③ Remaining is income minus everything planned. |
| Intro 2 | Send each part where it is spent | When income arrives, move each Account's share in your bank app. | ① Tick Gaji when the money arrives. ② Jago needs Rp 2.800.000, Mandiri Rp 2.200.000. ③ Move it in your bank app, then record it here. |
| Intro 3 | Tick off and spend as you go | Fixed items get paid once; Envelopes fill with everyday spending. | ① Paying Kos marks it Done. ② Harian counts every Makan and Transport expense. ③ Remaining stays Rp 3.000.000: the spending was planned. |
| 1.1 | Pick a cycle and fill it in | Page to any cycle, even a future one, and start planning. | ① Page between cycles with ‹ and ›. ② Enter the income you expect, by name. ③ Add plan item adds what the money is for. |
| 1.2 | Start from an earlier plan | A new cycle stays empty until you choose how to fill it. | ① Copy from brings an earlier plan's items and amounts. ② Start empty when this cycle looks different. ③ Look back adds items you missed from earlier. |
| 2.1 | Three kinds of plan item | Each item says how that money will be spent. | ① Fixed: one payment, like rent. ② Envelope: an allowance for many purchases. ③ Set aside: money kept now for a later cycle. |
| 2.2 | Save now for a later cycle | Set aside sends this cycle's money to a later Envelope. | ① December's Liburan receives this Rp 1.000.000. ② It takes Rp 1.000.000 off this cycle's Remaining. ③ Tick it once the money is moved to Jago. |
| 3.1 | The row edits, the check tracks | Tap a row to change it; its check moves it forward. | ① Tap the row to edit its name, amount or Account. ② Moved to Mandiri: Kos is Funded, the money is waiting. ③ Paid: Kos is Done and its Expense is recorded. |
| 3.2 | Let due items post themselves | A due day keeps Kos on time; Auto records it for you. | ① Due 5: Kos is due on the 5th. ② Auto records the payment once the 5th has passed. ③ Undo Done takes Kos back to Funded. |
| 4.1 | See where income needs to go | The transfer checklist adds up what each Account needs. | ① Tick Gaji when it arrives. ② One line per Account: what Jago and Mandiri need. ③ Without an Account, Kos needs no transfer line. |
| 4.2 | Move part of it now | Pick which items to send; the rest waits for later. | ① Deselect Liburan to keep it for later. ② Transfer now drops to Rp 1.800.000. ③ After moving it in your bank app, record Moved to Jago. ④ Harian is Funded; Jago still has Rp 1.000.000 to go. |
| 5.1 | Watch an Envelope fill | Every Makan and Transport expense counts against Harian. | ① Rp 1.680.000 left of Rp 1.800.000. ② + adds an expense here, or moves one in. ③ Mark Harian as its Envelope while you add it. ④ Harian now shows Rp 165.000 spent. ⑤ Overspending shows in red; logging is never blocked. |
| 5.2 | When money comes from elsewhere | Spending from another Account or cycle still lands in the right place. | ① Grab Rp 75.000 was paid on CC Danamon, not Jago. ② After the real move, record Moved from Jago. ③ Paid early: a November ticket counts in December's Liburan. |
| 6.1 | Sort and group your plan | Order rows by what matters now, and see each group's share. | ① Six orders: Amount, Account, Group, Due day, Status, Name. ② Account groups rows under each Account. ③ Group shares: each group's planned share of income. |
| 6.2 | Notices, and a clean slate | Notices ask for a look; Clear Plan empties an upcoming cycle. | ① Review Auto payments when this notice appears. ② Clear Plan empties an upcoming plan; Expenses stay. |

The sample is `plan-guide.md` §5, plus three illustration-only entries the snapshots need:
an extra Makan expense of Rp 45.000 marked to Harian (5.1 ③–④), Harian at Rp 1.950.000
spent (5.1 ⑤), and Tiket pesawat Rp 300.000 bought in November and paid early for December's
Liburan (5.2 ③). English uses Remaining for Sisa. Group shares show whole percentages as
the app does, rounding down (28 %, 22 %, 12 %). The Auto review notice is the app's own:
"1 Auto item posted", "Written without confirmation. Check the amount."

#### What the frames draw by convention

- Account plates are neutral (card glyph on the surface colour); the build uses the real
  `AccountPlate`, including bank logos.
- 3.1 ②–③ do not draw the check's menu; the caption names the choice.
- 5.1 ③ draws the editor compressed (title, amount, Category, Envelope row); the build
  shows the real `ExpenseEditorView` content inert, with WHEN, People and the keypad as the
  editor lays them out, scrolled so the Envelope row is in view.

### 4.6 Accessibility

- VoiceOver announces the caption when the spotlight changes. The example is one
  element labelled with the step's example title; its parts are not read separately.
- At large text the example and caption scroll; on Next or Back the active spotlight
  scrolls into view. Footer actions stay reachable, as today.
- Dimming never carries meaning alone: the caption names the element.

---

## 5. Lifetime

| Event | Result |
|---|---|
| Open a step (resume, Next across steps, reread) | Spotlight 1 of that step |
| Back across steps | Previous step, last spotlight |
| Close / Topics / relaunch mid-step | Saved step as today; spotlight forgotten, resumes at 1 |
| Finish a material | As `plan-guide.md` §4.5 and §6 |

Saved progress keeps the format of `plan-guide.md` §6 (key `planGuideProgress`); no
migration, and progress saved by the shipped guide stays valid.

## 6. Unaffected

| Behaviour | Stays as |
|---|---|
| Invitation card, its states and where it shows | `plan-guide.md` §4.1 |
| Topic index, groups, row states, Back to Plan | `plan-guide.md` §4.3 |
| Material ids, step counts, Read / In progress | `plan-guide.md` §4.3, §6 |
| Plan options menu, Clear Plan | `plan-guide.md` §4.1 |
| User's plan, Expenses, filters, sort, notices | No writes, no reads by the example |

---

## 7. Decision log

| # | Decision | Frames |
|---|---|---|
| 1 | Show real SwiftUI components with spotlights, instead of hand-written example cards | AN2–AN16 |
| 2 | Wonder track, flow on page 05 next to Flow AM | Flow AN header |
| 3 | Edge-case rules removed from the guide; the happy path only | AN2–AN16 |
| 4 | Keep 7 materials and 15 steps; ids and saved progress unchanged | AN2–AN16 |
| 5 | One spotlight at a time, the rest dimmed — *owner override*, against numbered pins with a caption list | AN2–AN16 |
| 6 | Next walks the spotlights, then the steps; Back walks them backwards | AN2–AN16 |
| 7 | Only the step is saved; a reopened step starts at spotlight 1 | — |
| 8 | Back across steps lands on the previous step's last spotlight | AN16 |
| 9 | Heading, one-sentence lead and the active caption; takeaways removed — *owner override*, against dropping the lead | AN2–AN16 |
| 10 | A spotlight may swap the example to a new snapshot, crossfade under Reduce Motion | AN3, AN4, AN9–AN15 |
| 11 | The example is inert; Next is the only way forward — *owner override*, against the spotlighted element acting as Next | AN2–AN16 |
| 12 | Index, invitation and Plan options menu unchanged | — |
| 13 | Own PRD, `plan-guide-visual.md`; `plan-guide.md` §4.4 points here | — |
| 14 | Content contract §4.5 replaces `plan-guide.md` §4.4 | AN2–AN16 |
| 15 | Default: sample in an in-memory store owned by the guide | AN2–AN16 |
| 16 | Default: two to five spotlights per step (two to four as proposed; 5.1 grew to five by #23), ●○○ dots above the caption | AN2–AN16 |
| 17 | Default: "EXAMPLE · NOVEMBER" label and "Your data stays unchanged" footer kept | AN2–AN16 |
| 18 | Default: lead and captions at most about 15 words | AN2–AN16 |
| 19 | Default: VoiceOver reads the caption; the example is one labelled element | AN17 |
| 20 | Default: at large text the active spotlight scrolls into view | AN17 |
| 21 | Default: new strings as id/en catalog keys; Remaining in English | All |

| 22 | Spotlight look: 2 pt accent ring on the active element, the rest at 30 % opacity; ring space reserved so nothing shifts | AN2–AN16 |
| 23 | 5.1 gains two spotlights: the expense editor with Envelope = Harian, then Harian's spent rising to Rp 165.000 — *owner request* at the design gate; chosen over a new step and over replacing the + spotlight, keeping 15 steps | AN13 |
| 24 | Intro 2 ③ shows the transfer sheet's Moved to Jago button under the checklist | AN3 |
| 25 | 4.1 ③ is a snapshot that removes Kos's Account, because the sample has no item without one | AN11 |
| 26 | 3.2 ② adds an Auto posted snapshot so ③ Undo Done has something to undo | AN10 |
| 27 | 1.2 ③ uses Harian from October for the Look back row | AN6 |
| 28 | 3.1 ②–③ keep the spotlight on the check; its menu is not drawn and the caption names the choice | AN9 |
| 29 | 4.2 ④ replaces the sheet with Jago's half-filled checklist line and Harian's funded row | AN12 |
| 30 | 5.2 ③ uses the §5 paid-early variant, drawn as Tiket pesawat Rp 300.000 | AN14 |
| 31 | 6.1 ① shows the sort menu open over the rows; group shares in whole percentages | AN15 |
| 32 | 6.2 notice copy "1 Auto item posted · Kos · Rp 2.200.000 on 5 Nov. Check the amount."; ② on the December 2026 cycle | AN16 |
| 33 | Account plates drawn neutral in the frames; the build uses `AccountPlate` | AN3, AN11, AN12, AN14 |
| 34 | Headings, leads and captions as §4.5 Words | AN2–AN16 |
| 35 | AN17 shows AN9 ② at a large text size, not a captured scroll position | AN17 |

Decisions 1–14 approved by the owner on 16 November 2026; defaults 15–21 approved with them.
Design calls 22–35 approved at the design gate on 16 November 2026, after the revision in #23.

### Closed during implementation

| # | Gap | Answer in the build |
|---|---|---|
| C1 | How the guide gets SwiftData models without touching the owner's store | `PlanGuideSample` builds the §5 sample in its own in-memory `ModelContainer`, one per sample state, cached for the visit (`PlanGuideSampleCache`); fixed to November 2026, payday 1, today 1 Nov so Kos reads "Due 5" |
| C2 | How a spotlight finds an element inside a real view | Plan views call `planGuideTarget(_:)`; it reports geometry only when a guide example supplies a `PlanGuideTargetRegistry`, so the Plan lens measures nothing. Anchor preferences were tried first and failed: the Fixed row's chip line is a `ViewThatFits`, which drops its children's preferences (Due and Auto chips never lit) |
| C3 | Dimming and the ring without shifting layout | One overlay over the example: canvas colour at 70 % with an even-odd hole, a 2 pt accent ring 4 pt outside the element. Nothing is added to the parts, so no space needs reserving |
| C4 | 4.2's sheet needs `modelContext` and holds its choice as state | The guide composes `TransferSheet`'s own parts (`TransferPickRowView`, `TransferAdjustmentRow`, `TransferFigureRow`, `TransferRecordButton`) over the same `TransferPick`; the choice comes from the sample state. The sheet's Adjustment row stays |
| C5 | 5.1 ③: can `ExpenseEditorView` render inert? | Not usefully: it needs the receipt reader environment, a keypad dock and a sheet. The guide draws the editor's `AmountHero`, `CategoryGrid` and `EnvelopeFormRow` with Envelope = Harian |
| C6 | Open menus (5.1 ②, 6.1 ①, 6.2) | A SwiftUI `Menu` cannot be opened from code; `PlanGuideMenuPanel` draws the items. 5.1 ②'s menu is lit beside the ＋ ring without a second ring |
| C7 | 3.2 ②: Due 5, Auto and Review overflow the chip line, truncating "Auto" | 3.2 hides the Account chip (`planRowsShowAccount = false`) |
| C8 | Set-aside line name | The sample names Liburan's line after its target, as `PlanItemEditorView` does; it showed blank in the transfer sheet until fixed |
| C9 | Captions under the footer on long examples | Spotlight 1 scrolls only the lit part into view, keeping the heading; later spotlights scroll the lit part and its caption in together |
| C10 | Amounts in captions | Format arguments through `formattedIDR()`, so Indonesian reads "Rp1.680.000" like the rest of the app |
| C11 | Words the real views set | Paid elsewhere captions are the row's own ("Move from Jago", "Moved from Jago"); the paid-early row is the List lens's expense row (Tickets · Flight ticket, → Liburan · Dec); the PLAN header reads "3 items · none done yet"; CycleHeader keeps its Remaining hero |
| C12 | Screenshots of any spotlight | DEBUG `-planGuide <material>:<step>:<spotlight>`, walking back as well as forward from saved progress |

## 8. Design traceability

Page 05, **Flow AN · Plan guide, shown not told**. One column per frame; for steps with
snapshots, the column shows each spotlight as its own phone (every step's column shows all its
spotlights). Column captions sit above the phones; frame ids are in
`.scratch/plan-guide-visual/wonder.json`.

| Frame | State |
|---|---|
| AN1 | Before: a copy of shipped AM13, beside AN2; compare with AN12 |
| AN2–AN4 | Introduction steps 1–3, every spotlight |
| AN5–AN6 | Topic 1, start a plan |
| AN7–AN8 | Topic 2, allocation types and Set aside |
| AN9–AN10 | Topic 3, row actions, Auto and undo |
| AN11–AN12 | Topic 4, transfer destinations and partial transfer |
| AN13–AN14 | Topic 5, Envelope (five spotlights, ③ the expense editor) and other Accounts / cycles |
| AN15–AN16 | Topic 6, view and notices; AN16 also shows Back landing on AN15's last spotlight |
| AN17 | Accessibility XL: scrolled example with the active spotlight in view |
