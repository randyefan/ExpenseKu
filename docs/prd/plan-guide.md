# PRD — Plan guide

Status: Built
Date: 2026-11-15
Owner: Randy Efan

Design: Wonder **ExpenseKu → 05 · Proposals — not built → Flow AM · Plan guide, expanded — built**
(kept on page 05 like every built flow until the page 02 migration).
Flow AM supersedes the narrower Flow AL, which remains available for comparison.

Companions: `CONTEXT.md`, ADR-0005, `payday-planning.md`, `clear-plan.md`,
`partial-transfer.md`, `set-aside.md`, `envelope-detail.md`, `envelope-assignment.md`,
`paid-elsewhere.md`, `look-back.md`, and `plan-sort.md`.

## 1. What this is

An optional introduction to using Plan throughout a pay cycle, followed by six
independently readable topics. The guide explains what to do before payday, which
Accounts need money when income arrives, what actions plan rows offer, and how actual
spending relates to planned allocations. It uses illustrative examples only.

Plan is the whole cycle's allocation. Fixed, Envelope and Set aside are kinds of
PlanItem inside it, not competing alternatives to Plan. `[→ AM2, AM8, AM9]`

The entry extends `PlanEmptyState` in `CyclePlanLens`; `PlanContents.hasPlan` distinguishes
an absent plan from an existing empty plan. Menu presentation and guide state live
above the lens identity in `ExpensesView`, preserving the originating cycle and view.

## 2. Goals

1. Teach the complete routine: plan, prepare Accounts on payday, then record and review spending.
2. Make the transfer checklist a visible reason to use Plan.
3. Explain Fixed, Envelope, Set aside, Funded, Done and their different effects.
4. Cover all six topics in version one, with advanced reading optional.
5. Preserve progress and offer direct access to any topic without changing real data.

## 3. Non-goals

- Interactive practice, automatic transfers, bank connections, sample records or guided data entry.
- Changing any existing planning, spending, filter, notice, transfer or deletion rule.
- CloudKit guide-progress sync or a schema migration.
- Requiring the six topics to be read in order or to hide the introductory invitation.

## 4. Rules

### 4.1 Entry points

| Current cycle | Intro state | Invitation | Plan options menu |
|---|---|---|---|
| No plan | Not started | Meet Plan / View guide | Plan guide |
| No plan | In progress | Meet Plan / Continue introduction | Plan guide |
| No plan | Complete | Hidden | Plan guide |
| Existing plan, including zero or one item | Any | Hidden | Plan guide |

`[→ AM1, AM19, AM21]`

The invitation opens the introduction at its saved incomplete step; it never opens
automatically. Its description mentions the payday routine and topic library.
Existing Start, Copy from and Start empty actions remain available below it.
The Plan options menu is available throughout the Plan lens, including no-plan cycles;
Plan guide opens the topic index, not the last visited lesson. Clear Plan remains
available only for an existing upcoming-cycle plan and follows its existing confirmation.
`[→ AM1, AM5, AM19–AM21]`

### 4.2 Introduction

Three full-screen steps provide orientation, not a condensed manual:

| Step | Teaches | Example | Finish action |
|---|---|---|---|
| 1 · Before payday | Pick a cycle, enter expected income, allocate it with Fixed, Envelope and Set aside; read Sisa | Income 8m, planned 5m, Sisa 3m | Next |
| 2 · On payday | Mark income arrived, read transfer destinations, move money externally, then record the move | Mandiri 2.2m, Jago 2.8m | Next |
| 3 · Through the cycle | Record actual payments, track envelopes, revisit and adjust the plan | Kos Done; Harian 120k spent | Explore topics |

`[→ AM2–AM4]`

Explore topics marks only the introduction complete, hides the invitation and opens
the topic index. Close before that keeps the displayed step and returns to Plan.
No guide action creates a CyclePlan, IncomeLine, PlanItem or Expense. `[→ AM4, AM5, AM19, AM21]`

### 4.3 Topic index

The index is a full-screen guide home with a Close action labelled Back to Plan.
It presents an introduction block followed by six topics in the order below.
All are available immediately, including when the user has no plan or has not
finished the introduction. There are no locked topics or forced prerequisites.
`[→ AM5, AM18]`

Each material has its own local state: Not started, In progress (step N of 2 or 3),
or Read. A tap on an incomplete material resumes its last displayed step; a Read
material starts from step 1. A prominent Continue action in the introduction block
applies to that introduction only; it does not silently select another topic.
`[→ AM5, AM18]`

The index may scroll; all six rows and their status must be reachable. Never imply
that the topic library is complete merely because the introduction is complete.
`[→ AM5, AM18]`

### 4.4 Topic coverage and order

Each topic has two short full-screen lessons. The lesson table is also the content
contract: text may be shortened during implementation without dropping these rules.

| Topic / lesson | Required content | Frame |
|---|---|---|
| 1 · Start a plan / Choose a cycle | Plan shares List/Month's pay-cycle navigation; future planning is allowed. Enter named expected Income and add allocations from Add plan item. Toolbar + logs an Expense. Income is not an Expense or a bank balance | AM6 |
| 1 / Reuse and fill gaps | No automatic copy on arrival. Copy from uses an earlier plan; Start empty remains possible. Amounts carry over, arrival/Funded/Done progress does not. Zero unused carried-over rows are dormant and wake by editing. Look back brings missing earlier items or Outside plan categories into this plan; it excludes Set aside and does not edit the earlier plan | AM7 |
| 2 · Allocation types / Plan and its items | Plan contains all three kinds. Fixed represents one payment and creates a linked Expense when Done is confirmed. Envelope is an allowance across purchases, by its categories or explicit assignment; Fixed-linked Expenses are excluded. It never creates an Expense | AM8 |
| 2 / Set aside for later | Add Set aside through Add plan item, select an Envelope in an existing later plan and optionally an Account. No target: create a later plan's envelope first. It reduces this cycle's Sisa and credits the target from the moment the line exists. Its moved tick creates no Expense and does not change Sisa. It has no Funded stage and is never copied forward | AM9 |
| 3 · Manage plan items / Row versus status | Tap the body to edit Fixed/Set aside or inspect an Envelope. A Fixed check with an Account offers Moved to Account and Paid; Funded means money is there, not paid. Paid confirms actual amount/date and creates the Expense. Without an Account there is no Funded stage. Envelope stops at Funded; Set aside has its separate moved tick | AM10 |
| 3 / Dates, Auto and undo | Fixed can have a due day; Auto requires it. Auto posts at the planned amount when the app is next opened after the due date, regardless of Funded, and needs review. Undo Done confirms deletion of the linked Expense, landing on Funded if an Account exists, otherwise Todo. Not moved yet clears Funded. Deleting an item keeps an existing Expense | AM11 |
| 4 · Payday transfers / See destinations | Mark actual income arrived. Transfer checklist groups allocations by optional Account; items without one do not form a destination. It shows where money is needed, not the income's source or an account balance. Do the actual transfer in the banking app; the guide/app never sends money | AM12 |
| 4 / Move some now | Tap an Account, choose Todo items, review Transfer now and record Moved to Account after moving the money. Opening chooses all Todo items; deselect to transfer partially. Adjustment counts in the first round only; a negative adjustment reduces the amount needed. Already in shows Funded/Done items; an undo returns Funded items to To send. Set aside uses its moved state, not Funded. Checklist states are derived, not manually ticked | AM13 |
| 5 · Follow an Envelope / See and assign spending | Tap the body for counted Expenses, remaining allowance and earlier contributions. + offers Add Expense or Move expenses here; explicit assignment overrides category routing, No envelope opts out. A Category belongs to at most one Envelope per plan; Fixed-linked Expenses are excluded. An empty Envelope has 0 spent. Overspending is visible and does not block logging | AM14 |
| 5 / Other Accounts and cycles | Paid elsewhere appears only when both Accounts exist and differ; select Expenses and record Moved from the envelope Account after the real move. This does not change Sisa or record another Expense. Paid early assigns a real Expense to an existing later Envelope: it stays dated in its original ledger, counts in the later Envelope and adjusts both plans' Sisa with the later credit capped at planned allowance. Contrast with Set aside: no purchase, uncapped planned credit | AM15 |
| 6 · Read and tidy Plan / Change the view | Six orders: Amount, Account, Group, Due day, Status, Name. Account/Group/Status group rows. Due day follows the cycle's order. Funded notice filters unpaid Fixed items; totals stay. It forces Amount and hides sorting while active. Group shares are planned percentages of income, not actual spending | AM16 |
| 6 / Notices and clearing | Notice priority: review, carried-over, Funded, payday; review Auto amounts first. Sort resets on cycle paging/relaunch, survives lens switch. Clear Plan is only for upcoming plans; its confirmation names lost links and keeps Expenses. Clearing does not restart the guide | AM17 |

`[→ AM6–AM17]`

This guide explains shipped rules; where a companion PRD has been amended, its latest
amendment and current source take precedence. In particular transfer status is derived
from members, carry-over is explicit, and Set aside has its own two-state tick.

### 4.5 Lesson navigation and completion

Lessons are full-screen modals over Plan, hiding the underlying tab bar. Each shows
the material name, Step N of N, and Close. The first step has Topics to return to the
index; later steps have Back to the previous step. Next advances exactly one step.
The last topic step has Finish topic, marks that topic Read and returns to the index.
The last intro step has Explore topics and marks only the intro complete.
`[→ AM2–AM18]`

Topics, Close and Back never mark a new material complete. Persist the step actually
displayed, including a step reached through Back. Reopening a completed material starts
at step 1 and retains Read even if the reread is closed early. Finishing a topic never
completes the introduction. Back to Plan from the index and Close from a lesson dismiss
the guide to its originating Plan context, with no data writes. `[→ AM5, AM18–AM21]`

### 4.6 Language and accessibility

Follow the app's chosen language and existing domain labels. Canvas artifacts use
English, including Fixed, Envelope and Set aside. Do not call Plan a fourth item kind,
or call Account a tracked balance. `[→ AM1–AM21]`

Use app theme/type tokens, at least 44-point action targets, explicit textual progress
and VoiceOver reading order. Lessons and the index scroll with large text; bottom
navigation remains reachable above the home indicator. Do not truncate essential
instructions or require a swipe to reveal the only Next action. `[→ AM2–AM18]`

## 5. Sample story

One dataset is reused throughout. Each frame names the stage of this example;
illustrative status transitions never apply to the user's data. `[→ AM2–AM17]`

| November 2026, payday 1 | Kind | Planned | Account | Group |
|---|---|---|---|---|
| Gaji | Income | Rp 8.000.000 | — | — |
| Kos | Fixed, due 5 | Rp 2.200.000 | Mandiri | Housing |
| Harian | Envelope, Makan/Transport | Rp 1.800.000 | Jago | Daily |
| Liburan · Dec | Set aside | Rp 1.000.000 | Jago | Travel via target |

Baseline: Total income 8m, Total cost 5m, Sisa 3m. Transfer destinations: Mandiri 2.2m,
Jago 2.8m, adjustment zero. December already has Gaji income of 8m and a Liburan Envelope planned at 2m on
Jago, with no categories. Its Total cost is 2m, Set aside in November is +1m,
and Sisa is 7m. November's 1m Set aside credits December; its own cycle puts
in 1m before any Paid early credit. `[→ AM2, AM3, AM8, AM9, AM12, AM13]`

| Later example stage | Change | Consequence |
|---|---|---|
| Payday | Gaji arrived; Harian selected in Jago's transfer sheet, Liburan not selected | Transfer now 1.8m; afterwards Harian Funded, Liburan not moved, Jago partial with 1m still to go `[→ AM13]` |
| Ordinary spending | Kos paid at 2.2m; Kopi 45k on Jago and Grab 75k on CC Danamon count in Harian | Harian spent 120k, left 1.68m; Sisa still 3m; Paid elsewhere 75k to move from Jago `[→ AM4, AM14, AM15]` |
| Paid early variant | A 300k ticket bought in November is assigned to December's Liburan | November Sisa 2.7m; December credit includes paid early 300k plus Set aside 1m; its remaining contribution is 700k `[→ AM15]` |
| Auto illustration | Kos could instead be configured Auto with due day 5 | Same 2.2m allocation; describes an alternative setting, never a second Kos payment `[→ AM11]` |

Group shares in the baseline: Housing 27.5%, Daily 22.5%, Travel 12.5%, leaving 37.5%
unallocated. No account balance is invented. The intro's invitation uses the user's
absent-plan state (Sisa 0), not the sample totals. `[→ AM1, AM16, AM19, AM21]`

## 6. Lifetime and unaffected behavior

Persist seven independent material states locally: intro plus six topics.
Use stable material identifiers, last incomplete step and completion flags.

| Event | Result |
|---|---|
| First invitation tap | Intro step 1 `[→ AM1, AM2]` |
| Invitation with incomplete intro | Resume its saved step `[→ AM19]` |
| Plan guide menu | Always index `[→ AM5, AM18, AM20]` |
| Topic row before completion | Resume that topic's saved step `[→ AM18]` |
| Topics return / Close / relaunch | Preserve individual steps and flags `[→ AM18, AM19]` |
| Finish intro | Intro complete, invitation hidden; topics unchanged `[→ AM4, AM5, AM21]` |
| Finish topic | Only that topic Read; return to index `[→ AM7–AM18]` |
| Reread completed material | Step 1; Read remains true during reread `[→ AM18]` |
| Cycle paging, lens switching, create/copy/clear plan | Guide progress unchanged; invitation follows current plan existence and intro completion `[→ AM1, AM19–AM21]` |
| Existing empty/single-item plan | No card, all topics still available through menu `[→ AM20]` |
| Another device or fresh install without preferences | Fresh local guide state `[→ AM1, AM5]` |

| Existing behavior | Unaffected by guide |
|---|---|
| Expense filters, From plan/Outside plan, Funded filter and Plan sort | Preserve values on opening/closing; guide samples ignore them `[→ AM16, AM20]` |
| Review, carried-over, Funded and payday notices | Preserve order and seen flags; opening guide never counts as acting on a notice `[→ AM17, AM20]` |
| Income, items, transfer/moved states, Expenses and Sisa | No guide data writes `[→ AM2–AM17]` |
| No-plan start and copy alternatives | Remain available; no automatic plan creation `[→ AM1, AM19, AM21]` |
| List, Month, Insights, Search and Manage | No new guide entry points or other changes `[→ AM1, AM20]` |

## 7. Decision log

Decisions 1–19 were approved before Flow AL. The owner declined that design's narrow
scope; revised decisions 20–29 were approved before Flow AM. This table describes the
current specification, not the abandoned three-concept tutorial.

| # | Current decision | Frames |
|---|---|---|
| 1 | Optional card entry inside Plan, never automatic | AM1 |
| 2 | Examples only, no data entry or writes | AM2–AM17 |
| 3 | Intro has three steps; revised content follows plan → payday → spending | AM2–AM4 |
| 4 | Full-screen — *owner override*, against a large sheet | AM2–AM18 |
| 5 | Local progress survives relaunch | AM18, AM19 |
| 6 | Resume last incomplete step | AM18, AM19 |
| 7 | Completed material reopens from step 1 | AM18 |
| 8 | Card only without a plan and with incomplete introduction | AM1, AM19, AM21 |
| 9 | Plan guide menu available with or without a plan | AM20 |
| 10 | Leaving guide returns without creating a plan | AM21 |
| 11 | App language and existing terms | All |
| 12 | Separate PRD, `docs/prd/plan-guide.md` | Flow AM header |
| 13 | Wonder file ExpenseKu, proposal page | Flow AM header |
| 14 | Card above empty state; continue label for incomplete intro | AM1, AM19 |
| 15 | Progress spans cycles/lenses; clearing plan does not reset it | AM18–AM21 |
| 16 | Expanded, consistent sample with Accounts and a future envelope | AM2–AM17 |
| 17 | Explain plan versus actual spend, not just allocation arithmetic | AM4, AM8–AM15 |
| 18 | Preserve original filters, notices, calculations and data | AM16, AM17, AM20 |
| 19 | Earlier exclusion of advanced features superseded by decision 21 | — |
| 20 | Intro plus topic library, rather than one long mandatory tour | AM2–AM18 |
| 21 | All six topics in version one, including advanced features; supersedes narrow Flow AL | AM5–AM17 |
| 22 | Hide invitation when intro completes, not when all topics complete | AM4, AM21 |
| 23 | Menu always opens topic index | AM5, AM18, AM20 |
| 24 | Final lesson action returns to topic index; Back to Plan dismisses | AM4, AM7–AM18 |
| 25 | Topic order: start, types, item actions, payday, envelopes, reading/tidying | AM5, AM18 |
| 26 | Topics available from the outset, without prerequisites | AM5 |
| 27 | Each material keeps its own progress | AM18 |
| 28 | Keep full-screen examples, language and existing interaction safeguards | All |
| 29 | Broader sample includes destination Accounts, Set aside and status changes | AM2–AM17 |
| 30 | Flow AM and all section 8.1 design calls approved on November 15, 2026; proceed to implementation | All |

## 8. Design traceability

Page 05, **Flow AM · Plan guide, expanded**, new copies of Flow AL's app chrome.

| Frame | State |
|---|---|
| AM1 | Invitation in Plan |
| AM2–AM4 | Introduction: before payday, on payday, through the cycle |
| AM5 | Index after intro complete, no topics read |
| AM6–AM7 | Topic 1, start a plan |
| AM8–AM9 | Topic 2, allocation types and Set aside |
| AM10–AM11 | Topic 3, row actions, Auto and undo |
| AM12–AM13 | Topic 4, transfer destinations and partial transfer |
| AM14–AM15 | Topic 5, Envelope details, other Accounts and cycles |
| AM16–AM17 | Topic 6, sort/filter/shares, notices and clearing |
| AM18 | Index with independently saved/read topic states |
| AM19 | Continue incomplete intro, with copy-source empty-state alternative |
| AM20 | Menu on an upcoming existing plan: Plan guide before Clear Plan |
| AM21 | Intro complete: card hidden, original start action available |

### 8.1 Approved design calls

The owner approved Flow AM and all calls below on November 15, 2026.

- Keep the app's dark palette, Plus Jakarta Sans, pill actions and tokenized cards.
- Keep three progress segments for intro, two for each topic, plus explicit step text.
- Topic index uses two groups: Build your plan (topics 1–3), Use your plan (4–6).
- Index rows show Not started, Step N of 2 or Read; advanced content is optional reading.
- Intro finishes with Explore topics; topics finish with Finish topic. Topics goes back
  to index; Close dismisses to Plan. Index uses Back to Plan.
- Examples are static, labelled, and separated from instructions. Transfer examples
  explicitly distinguish a bank-app action from recording a fact in ExpenseKu.
- Icons are Feather canvas equivalents; implementation uses corresponding SF Symbols.
- English artifacts follow the existing design convention; runtime follows app language.

### 8.2 Verification and limits

Built 15 November 2026 on `feature/plan-guide`. `PlanGuideTests` holds one test per rule of
§4.1, §4.2, §4.3, §4.5 and §6 (30 tests); Debug and Release suites pass with no new warnings.

The Device panel opened the simulator and read its accessibility tree, but every tap failed
("Runner did not accept connection: this Xcode cannot start its simulator service on this
macOS"), as in the proposal stage. No other device control was used. Instead a DEBUG-only
`-planGuide index|invitation|<material>:<step>` launch argument opened each state for a
screenshot, and navigation (Next, Back, Topics, Finish, Close, reread) is covered by tests.

| Observed in the simulator | Frame |
|---|---|
| No plan, intro not started: Meet Plan / View guide above the empty state; ••• menu present | AM1 |
| Intro steps 1–3, with Topics / Back / Next / Explore topics | AM2–AM4 |
| Topic lessons, including the partial-transfer selection example | AM13, AM15, AM16 |
| Index with independent saved states after several relaunches | AM18 |
| No plan, intro in progress: Continue introduction | AM19 |
| Existing plan: no card, ••• menu present | AM20 |
| Indonesian index and lesson copy | All |
| Accessibility XL: lesson scrolls, footer actions stay reachable | AM2–AM18 |

Covered by tests only, because they need a tap: opening the menu (Plan guide before Clear
Plan), completing the intro to hide the card (AM21), Back/Topics/Finish persistence, and
rereading a Read topic.

### 8.4 Closed during implementation

| Gap | Resolution |
|---|---|
| English word for Sisa | The app's English label is Remaining; the guide follows it (§4.6). Frames AM2, AM4, AM9 and AM15 synced. Indonesian keeps Sisa |
| Index intro block before the intro starts (no frame) | "Not started · 3-step introduction" with Start introduction |
| Status of a material opened at step 1 then closed | Step 1 of N: opening counts as started |
| Plan options menu while searching | Shown whenever the lens is Plan, matching how Clear Plan already behaved |
| Invitation card width | Inset like the Start / Copy buttons below it, not the header card above |
| Progress storage | `UserDefaults.standard`, key `planGuideProgress`, JSON per material; unreadable data starts afresh |
| Example amounts | Formatted with the app's IDR format for the current locale, so they match real rows |
| Example row at large text | Name and value stack when they no longer fit one line |

### 8.3 Proposal verification

All 21 Flow AM phone frames were exported and visually inspected. Text contrast in
the upcoming-plan menu context was corrected during review. Flow AL and all shared
main components remain unchanged. No app implementation or runtime validation is
claimed. Local review exports and canvas identifiers are in `.scratch/plan-guide/revision/`.
