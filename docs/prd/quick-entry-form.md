# PRD — Quick-entry expense form

Status: Built
Date: 2026-11-07 · designed, chosen (C4 + C6) and built the same day (flow AF)
Owner: Randy Efan

Companion documents: `CONTEXT.md` (ubiquitous language), `docs/prd/envelope-assignment.md`
(the Envelope row this form keeps), and **`design/ExpenseKu.pen`**, page
`02 · Pages · iPhone`, **Flow AF** (AF1–AF6). The options not chosen stay on
`05 · Proposals — not built` under the same letter; references like `[→ AF C4]` point there.

---

## 1. What this is

The expense editor (`ExpenseEditorView`) logs an Expense in four places: the amount on a
docked calculator keypad, then Date & Time, Category, Account and People. Three of those
four detail rows **push a picker** and come back, and the date is the iOS compact
`DatePicker`, which needs the calendar and the time wheel to move back a few hours.

The owner rarely logs an expense the moment it happens. A typical entry is "the lunch
three hours ago", "yesterday's parking". Today that is the slowest part of the form.

This feature puts every choice the owner makes on most entries **on the form itself**,
as one-tap chips, and keeps the pickers behind an "All…" chip for the rest.

## 2. Goals

1. Back-date an expense by a few hours, or to yesterday, in one tap.
2. Choose Category, Account and People without leaving the form for the common cases.
3. A new expense with the usual Account and only "Me" needs **amount → Category → ✓**,
   nothing else.

## 3. Non-goals

- **Changing the keypad's keys or the amount maths.** Layout options may move or fold
  the keypad; the keys, the expression evaluator and the ✓/Cancel semantics stay.
- **The Envelope and Note rows.** They keep today's behaviour.
- **The Save rule.** Still amount > 0 and a Category.
- **iPad and macOS layouts.** iPhone is designed here; the iPad page is stale and macOS
  keeps its Form.
- **Suggesting a Category from the note or the amount.**

---

## 4. The rules

### 4.1 When — date shortcuts `[→ AF1]`

A row of chips, in this order:

| Chip | Sets the date to | Selected when |
|---|---|---|
| **Now** *(default on Add)* | the current moment | the draft's date is within the current minute |
| **1h ago** | now − 1 hour | the draft's date equals now − 1 h, to the minute |
| **3h ago** | now − 3 hours | the draft's date equals now − 3 h, to the minute |
| **Yesterday** | the same clock time, one calendar day back | the draft's date equals that, to the minute |
| **…** | opens the full date-and-time picker | never; the picked value shows as its own chip |

- "Now" is captured when the chip is tapped, not when the form opened.
- Any date that no chip names (a picked date, or an edited expense's stored date) is shown
  as **one extra selected chip** carrying the value, e.g. `Mon, 3 Nov, 12.40`, placed
  ahead of Now. `[→ AF5, AF6]`
- The resolved date and time are always visible in the row, so "3h ago" at 01.00 reads
  as yesterday 22.00 and the owner sees it.
- The time stays editable on its own (tap the time, get the wheel) whatever chip is on.
- **Edit** shows the same chips, counted from now; the stored date is the extra chip.

### 4.2 Category `[→ AF1]`

- A **4 × 2 grid of tiles**: the **7 most used Categories**, counted over Expenses dated
  in the last 90 days, ties by name, then **All…** in the last tile. Stable order, so the
  owner's thumb learns the positions. `[→ AF C4]`
- Fewer than 7 used Categories: fill with the rest by name; fewer than 7 Categories in
  all: the grid keeps All… last and leaves the gap empty.
- **All…** pushes today's `CategoryPicker` (with its "New Category" row).
- A Category chosen through All… that is not in the grid takes the **first** tile,
  selected, for the life of the form; the seventh most used drops out. The same holds when
  editing an expense whose Category is not in the grid.
- A tile is the Category's icon in its tint over its name; selected = accent outline + wash.
- No Category selected: the section label reads **CATEGORY · REQUIRED** in accent.

### 4.3 Account `[→ AF C4]`

- One row, `ACCOUNT` label then a full-width **native Menu button** showing the chosen
  Account's bank logo or icon and its name. The menu lists every Account (logo, name, a
  check on the current one), then **None**, then **New Account…** (today's editor).
  `[→ AF C2]` draws the open menu.
- A new expense preselects the **Account of the most recently created Expense**; None
  when there is none.
- Order in the menu: by use in the last 90 days, then name; None and New Account… last.

### 4.4 People `[→ AF C4]`

- A sideways-scrolling rail of avatar chips, multi-select: **Me** (on by default for a
  new expense, as today), then the most tagged People over the last 90 days, then
  **All…**.
- **All…** opens a native Menu that **stays open while ticking**
  (`menuActionDismissBehavior(.disabled)`): every Person, avatar and name, a check on each
  one tagged; a tap toggles that Person; tapping outside closes it. Its last item,
  **Edit People…**, pushes today's `PeoplePicker` (where a new Person is added). `[→ AF C6]`
- A Person ticked through All… who is not on the rail joins it, selected, for the life of
  the form.

### 4.5 Layout `[→ AF C4]`

Top to bottom, above today's docked keypad (unchanged): AmountHero (tighter vertical
padding), WHEN rail, CATEGORY grid, PEOPLE rail, ACCOUNT menu row, the Envelope + Note
card. On a 402 pt phone the Note row sits under the dock and the form scrolls a little.
Chips are capsules; selected = amber outline on an amber wash; tints only inside the
leading mark. Rails run to the screen edge.

---

## 5. Lifetime

| Thing | Lives for |
|---|---|
| Selected chips | the draft, like every other field |
| The "most used" orders | computed when the form opens; they do not reshuffle while it is open |
| A Category/Person pulled in through All… | the open form |

## 6. Unaffected

The calculator keypad's keys, the Envelope row (`EnvelopeFormRow`) and its §4.10 rules,
the Note field, the discard confirmation, `PaidElsewhere.setAccount`, the macOS form.

## 7. Decision log

| # | Decision | By |
|---|---|---|
| 1 | Scope: Date, Category, Account, People move onto the form; keypad changes only as layout variants | owner |
| 2 | Date chips: Now · 1h ago · 3h ago · Yesterday · … | owner |
| 3 | Yesterday keeps the clock time; the time stays tappable | owner |
| 4 | Edit shows the chips too, counted from now; stored date is its own chip | owner |
| 5 | Category chips: 6–8 most used over 90 days + All… | owner |
| 6 | Account chips with logos; new expense = last used Account | owner |
| 7 | People: avatar chips, multi-select, Me on by default + most tagged + All… | owner |
| 8 | Labels in English, like the rest of the app | owner |
| 9 | A Category picked through All… goes first in the chip row | default |
| 10 | Envelope, Note and the Save rule unchanged; iPhone only | default |
| 11 | Layout C: Category as a 4 × 2 grid, Account as a menu, keypad unchanged | owner |
| 12 | Several People: People returns to an avatar rail (C4), Account stays a menu — *owner override* (recommended C3, a menu that stays open while ticking) | owner |
| 13 | Category grid holds exactly 7 + All…, replacing decision 5's 6–8 chips | follows from 11 |
| 14 | Account picks through a menu, not chips; the last-used default from decision 6 stays | follows from 11 |
| 15 | Selected chip = amber outline + wash; rails bleed to the screen edge; the resolved date pill opens the time wheel; "…" is a calendar glyph | design call, approved |
| 16 | People's All… opens the C3 menu (stays open, a check per Person) instead of pushing the picker; Edit People… at its foot pushes the picker | owner |

## 8. Design traceability

Flow AF on page 05 holds layout options A–D with one shared sample: Sat 7 Nov 2026,
20.15 now, Rp 45.000 Makan "Nasi padang", 1h ago (19.15), Jago, Me.

| Option | Frames | Shape |
|---|---|---|
| Now | B1 copy | shipped form, for comparison |
| A · Rails over the docked keypad | AF A1 add · A2 edit · A3 fresh | four sideways chip rails above today's keypad |
| B · The keypad folds away | B1 keypad up · B2 folded | When + Category rails over the keypad; folded, every chip wraps and Save is a full-width button |
| C · Category grid + menus | C1 · C2 Account menu · C3–C5 several People | 4 × 2 Category tiles, Account and People as native Menus; nothing scrolls. Several People: C3 menu stays open (`menuActionDismissBehavior(.disabled)`), C4 People back to an avatar rail, C5 a short sheet of avatar chips |
| D · Two steps | D1 amount + when · D2 details | ✓ becomes → Next; details page with grid and wrapped chips |

## 9. Closed during implementation

| Gap | Answer |
|---|---|
| How the resolved date and time are shown | The system's compact `DatePicker` (date and time capsules) on the WHEN line, not one drawn pill: native, and each capsule opens its own picker. `[→ AF1]` |
| "Most recently created" Account | An Expense has no creation timestamp and adding one is a schema change, so it is the Account of the **latest-dated** Expense logged by hand within the 90-day window; none there means None. |
| Plan-created expenses in the orders | Excluded everywhere, not only from the default Account: in the simulator an Auto item's "Cicilan" led the grid. |
| Fewer than 7 Categories | All… follows the last one directly; no empty tiles. |
| Calendar popover anchor | Anchored to the whole rail. Anchored to the calendar chip it slid off screen when the picked date's chip pushed the rail (found in the simulator). `[→ AF5]` |
| Custom chip wording | `Tue, 3 Nov, 20.58`: abbreviated weekday, day, month, then the short time. |
| Avatars and logos in menus | A system menu draws images as monochrome templates and cannot host views, so the People menu lists names only and the Account menu wears each Account's chip glyph. `[→ AF3, AF4]` |
| People never tagged in 90 days | Not on the rail; reached through All…. |
| The Envelope + note card | The editor is now a ScrollView, not a List, so the card is drawn with `Metric.cardRadius` (16) and `EnvelopeFormRow` carries its own chevron. `ExpenseDetailRows` is gone. |
