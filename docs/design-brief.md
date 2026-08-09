# Design Brief — ExpenseKu visual & view revamp

You are a senior product designer. I want you to redesign the **look and feel** of an
existing, working iOS/iPadOS/macOS app called **ExpenseKu** — new visual language and
refreshed screen layouts — **without changing what the screens do or how the user moves
between them.** You do not have access to the codebase; design against this brief.

## 1. What the app is
A **personal, single-user expense tracker** — one owner, their own money, no accounts,
no sharing, no server. Native Apple app (iPhone, iPad, Mac) built in SwiftUI. Its whole
job: log what I spent, and let me look back at it by pay cycle and by who/what/where.

It is NOT a bank app, NOT a budget app, and has NO income. Money only ever goes out.

## 2. Hard platform constraints (cannot change)
- **SwiftUI**, one codebase for **iPhone + iPad + Mac**. Any design must degrade
  gracefully across all three (compact iPhone, wide iPad/Mac). The main list uses a
  two-column (list + detail) layout on iPad/Mac and a single column that pushes to a
  detail on iPhone — keep that adaptivity.
- Charts are **Swift Charts** (bar charts).
- Currency is **Indonesian Rupiah (IDR)**, always whole numbers, e.g. `Rp275,000`.
  Money is right-aligned and uses **monospaced digits** so columns line up. Single
  currency — do not design a currency switcher.
- **Dark mode + Dynamic Type + VoiceOver** must all keep working. Don't encode meaning
  in color alone (important for the charts).

## 3. How it looks today
Essentially **stock SwiftUI**: system grouped `List`/`Form` styling, SF Symbols, system
fonts (`.headline`/`.subheadline`/`.caption`), the system accent/tint, a `.bar` material
strip for the cycle header, secondary-gray metadata text. Clean but generic and unbranded.
Assume there is currently **no custom design system** — you are creating one.

## 4. Screens to redesign (every surface + its states)

**A. App shell** — a 3-tab bar:
1. **Expenses** (home) · 2. **Insights** · 3. **Manage**.

**B. Expenses (home)** — the primary screen. Framed by the owner's **pay cycle**:
- A **cycle navigator header**: `‹` and `›` arrows, a title naming the cycle by the month
  it *ends* in (e.g. “August 2026”), the exact date span below it
  (e.g. “25/07/2026 ~ 24/08/2026”), and a **“Spending” total** for that cycle. Back arrow
  disables at the oldest data; forward arrow disables at the current cycle.
- Toolbar: **“+” add expense**, and a **calendar/settings button**.
- Below the header: expenses for that cycle, **grouped by day** with headers
  “Today” / “Yesterday” / “Thu, 6 August”.
- **Expense row**: category name (bold) + amount (bold, right); a meta line with the date,
  an optional payment account (with a small card icon), and optional companion names
  (“· Tarisa, Fadil”); an optional note line. Swipe-to-delete.
- States: **no expenses at all** (“Tap + to log your first expense”), and **empty cycle**
  (“No expenses this cycle” while the header/arrows stay).
- iPad/Mac: selecting a row opens an **editor in the right pane** (“No Expense Selected”
  placeholder when nothing is picked).

**C. Transaction Settings** (sheet from the calendar button): a single stepper
**“Monthly Start Date” (1–31)** — the day the spending cycle resets — with a one-line
explanation, and a Done button.

**D. Expense editor** (add/edit, shown as a sheet or in the detail pane):
- **Amount** (numeric, auto-focused when adding) and **Date**.
- **Category** (required — shows “Required” until picked), **Account** (optional — “None”),
  **People** (optional — “None”), each opening a picker.
- **Note** (multi-line).
- **Delete** (only when editing).
- **Save** (disabled until amount > 0 and a category is chosen) and **Cancel**.

**E. Pickers** (pushed screens):
- **Category** — single-select list with a checkmark on the current pick + “New Category”.
- **Account** — single-select, plus a “None” option.
- **People** — multi-select.
- **Name editor** — a name field used to create/rename Categories/People/Accounts; if the
  name already exists it shows a “‘X’ already exists” prompt with **Use existing / Create
  new anyway / Cancel**.

**F. Insights** — a scrolling screen of:
- A **period filter** (All time / Last 30 days / This month / This pay period / This year);
  choosing “This pay period” reveals an inline payday stepper.
- **Spend by Category** — horizontal bars with an IDR value on each; empty text otherwise.
- **Spend by Account** — same treatment (an “Unassigned” bar for expenses with no account).
- **Spend over Time** — vertical bars bucketed by month.
- A link to the **People leaderboard**.

**G. People leaderboard** (“Who you spend with”):
- Filters: period, category, account.
- A **ranked list**: rank number, person name, “N expenses”, total spent (right).
  Ranking credits the **full amount to each companion** on an expense (so totals can
  exceed the grand total — this is intentional, it’s “who I was *with*”, not bill-splitting).
- Empty state: “No People Yet”.

**H. Manage** — a menu to **Categories / People / Accounts**, each a simple list with
add (+), tap-to-rename, swipe-to-delete, and an empty state.

## 5. Vocabulary you must keep (don’t rename these in the UI)
Expense · Category · **Account** (a payment source label, e.g. Cash/GoPay — NOT a balance) ·
**Person / Companion** (someone I was *with*) · **Uncategorized** (category was deleted) ·
**Unassigned** (no account) · **Pay cycle / Monthly Start Date** · **People leaderboard**.
Never introduce “income”, “balance”, “budget”, “remaining”, or “net” — the app has none.

## 6. Guardrails — do NOT break the flow
- Keep every screen and every action reachable; keep the 3-tab structure (or, if you
  propose changing navigation, **flag it explicitly and separately** so I can veto it).
- Keep the **pay-cycle model**: one cycle at a time, end-month title, **spending-only**
  header (no income/net line), bounded arrows.
- Keep required-field logic: an expense needs a positive amount and a category to save.
- Keep an **empty state for every list**.
- Keep the iPhone-push / iPad-Mac-split adaptivity on the Expenses screen.
- Don’t design UI that implies out-of-scope features: **no budgets/limits, no income,
  no recurring, no receipt photos, no multi-currency, no bank import, no bill-splitting.**

## 7. What you MAY change (your creative surface)
Color palette (light + dark tokens), typography scale, spacing/rhythm, list-vs-card
treatments, the cycle-header composition, the expense-row layout, chart styling, icons,
empty-state illustrations, accent color, and tasteful motion/micro-interactions.

## 8. Aesthetic direction
<< FILL IN YOUR TASTE: e.g. “clean and calm, rounded cards, big legible numbers,
one accent color, minimal chrome” — or attach reference screenshots. >>

## 9. Deliverables
1. A **visual design system**: color tokens (light + dark), type scale, spacing, and named
   component styles (row, section header, cycle header, chart, empty state, buttons).
2. **Redesigned mockups** for each screen in §4, including its empty/edge states, at
   iPhone and iPad/Mac widths.
3. Notes mapping each component back to the screens above, and a short rationale.
4. A clear callout of **anything you changed about flow or navigation**, listed separately
   so I can approve or reject it before implementation.
