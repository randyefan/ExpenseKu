# ExpenseTracker — Context

Personal, single-user expense tracker. Native Apple app (iOS / iPadOS / macOS) built with SwiftUI + SwiftData, synced privately across the owner's devices via CloudKit. No accounts, no sharing, no backend.

This document is the source of truth for the project's **ubiquitous language**. When code, issues, or specs name a concept below, use the term as defined here — don't drift to synonyms.

## Glossary

### Spending

- **Expense** — a single record of money the owner **spent**. Carries an amount, a timestamp, a note, exactly one Category, zero or more People, and an optional Account. Distinct from a **PlanItem**, which records money the owner *intends* to spend (**ADR-0005**).
- **Amount** — the money value of an Expense, stored as `Decimal` in a single implicit currency (**IDR** for v1). There is no per-expense currency field yet; multi-currency is a future migration.
- **Category** — a reusable, owner-defined label for *what kind* of spend an Expense is (e.g. "Makan"). A first-class entity so it can be added or renamed without a rebuild. An Expense has exactly one, **required at entry**. (The stored property is optional for CloudKit's sake and may become nil only via category deletion — see **Uncategorized**.) A Category belongs to zero or one **Group**.
- **Uncategorized** — the display state of an Expense whose Category was deleted (`category = nil`). A valid state for *existing* expenses only; new expenses always require a Category.
- **Group** — (the Swift type is `CategoryGroup`, only because a type named `Group` would shadow `SwiftUI.Group` for the whole app; every string the owner reads says "group") a coarse, owner-defined bucket **above** Category, naming *what the money is for* rather than what was bought: "Fixed Obligations", "Lovely Support", "Housing & Living", "Entertainment & Lifestyle", "Personal Care", "Transportation & Travel". A Category belongs to at most one Group; a Group holds many Categories. Group is **never chosen when logging an expense** — it is inherited from the Category — and its only reader is the plan's percentage table. Category answers *what*, Group answers *what for*; they are different axes, which is why "Lovely Support" is a Group and not a Category.
- **Person** — a reusable entity naming someone an Expense is associated with: a **companion** the owner was *with* when spending, **or a recipient** the owner sent money to. An Expense can be tagged with many People; a Person appears across many Expenses (many-to-many).
  - Until **ADR-0006** a Person was strictly "who I was with" and beneficiaries were out of scope. That line was removed because the owner's plan is full of money sent *to* named people ("Kirim buat Ibu", "THR fara-eja-tarisa"). The app does **not** distinguish the two meanings — see **People leaderboard**.
  - Still out of scope: bill-splitting. There is no notion of who owes whom.
- **Companion** — a Person tagged on an Expense because the owner was *with* them. A sub-meaning of Person, useful in prose; the app stores no flag separating it from a recipient.
- **Account** — a reusable, owner-defined **payment source** an Expense was paid from (e.g. "Cash", "GoPay", a bank). A first-class tag-entity like Category, but **optional** on an Expense and single-select. It is a **label only** — *not* a balance-bearing ledger: no balances, income, top-ups, or reconciliation. Deleting an Account nullifies it on its expenses (ADR-0001), leaving them **Unassigned**.
  - A plan's **transfer line** groups planned spend by Account. That is a derived figure inside one plan, not a balance the app tracks.
- **Unassigned** — the display state of an Expense with no Account (`account = nil`), whether never set (accounts are optional at entry) or left behind by Account deletion. The Account analogue of **Uncategorized**.
- **Spend attribution** — how an Expense's amount is credited to its People for ranking. Rule: **full amount to each Person**. A 100k Expense tagged with two People counts 100k toward *each*. This is a per-person ranking, not a sum, so totals can exceed the grand total by design. Attribution is computed at query time; nothing extra is stored.
- **People leaderboard** — the analytics view ranking People by total attributed spend, with a count of shared Expenses, filterable by Category and date range. Since **ADR-0006** it ranks **both meanings of Person together** — companions and recipients, undifferentiated. It answers "who is the most money associated with," *not* "who did I spend the most time with"; the narrower question is deliberately not recoverable.

### The pay cycle

- **Pay period / Pay cycle** — the owner's spending cycle, anchored to a configurable **payday** (day-of-month, default 1, range 1–31, synced via `NSUbiquitousKeyValueStore`). Surfaced to the owner as **"Monthly Start Date."** As of **ADR-0004** the pay cycle is the **primary lens of the Expenses home screen**: the home shows one cycle at a time, titled by the month it *ends* in (25 Jul → 24 Aug is "August 2026"), with a per-cycle spending total and day sub-groups. A cycle is the half-open interval `[start, end)` from one payday to the next; a payday past the month's length clamps to the last valid day (a 31 anchor lands on Feb 28/29, so boundaries "walk"). The **This pay period** Insights preset shares the same anchor and clamp math (`PayCycle`) but keeps a spend-so-far end at *now* (**ADR-0003**). Single owner, monthly cycle.
- **Lens** — one of the ways the home renders the current cycle: **List**, **Month**, or **Plan**. Lenses share one cycle, one anchor, and one set of `‹ ›` arrows; switching lens never changes which cycle is shown.

### Planning

- **Cycle plan** — the owner's allocation of a cycle's income before it is spent: what is owed, what it is for, and what is left. Exactly one per pay cycle, using the same **Payday** anchor and the same cycle name as the home. A plan can be built for a cycle that has not started yet — that is the point of it.
- **Income line** — one source of money expected in a cycle: a name, an amount, and whether it **has arrived** yet ("Gaji Fulltime", "THR", a freelance payment). Income lines exist **only inside a plan**. They are never Expenses, never appear in Insights, and never create a balance or a net figure. Their sole purpose is to give **Sisa** and the **Group percentages** a denominator.
- **Total income** — the sum of a plan's income lines.
- **Total cost** — the sum of a plan's PlanItems, both kinds alike.
- **Sisa** — `Total income − Total cost`. What the plan leaves over. A number the owner reads, not a balance the app maintains; it can go negative, and nothing is blocked when it does.
- **PlanItem** — one line of a cycle plan: money the owner **intends** to spend. Not an Expense (**ADR-0005**). Comes in exactly two kinds, **Fixed** and **Envelope**. Carries a planned amount, a Category (and so a Group), an optional Account, optional People, and an optional **due day**.
- **Fixed** — a PlanItem standing for **one transaction**: "Kos Rp 2.200.000", "Netflix Rp 130.000". Completing it creates a linked Expense.
- **Envelope** — a PlanItem standing for an **allowance across many small purchases**: "Hidup (Makan, bensin, emoney saldo)". It names a **set of Categories** rather than one, and it **never creates an Expense**. Its **spent** figure is derived from Expenses already logged in that cycle whose Category is in the set. A Category belongs to at most one Envelope per plan, and an Expense created by a Fixed PlanItem is excluded from every Envelope — without that exclusion a completed "Kos" would be counted again inside the "Hidup" envelope sharing its Group.
- **Done** — the state of a Fixed PlanItem whose money has actually moved. Marking it done opens a short confirmation, and creates the linked **Expense** with the *actual* amount. The planned amount is kept, so a line can show **plan vs. actual**.
- **Dormant** — a PlanItem carried over from the previous cycle that is not in use this one (amount zero, never completed). Kept as a reminder, folded out of the main list. The plan's equivalent of the spreadsheet rows the owner keeps at Rp 0.
- **Due day** — an optional **day-of-month** on a PlanItem, clamped to the end of short months exactly as **Payday** is. On a Fixed item it is a reminder; on an **Auto** item it is what makes the item fire.
- **Auto** — a Fixed PlanItem the owner never acts on because the money leaves by itself (autodebit, a subscription). With a due day it **creates its own Expense** at the planned amount, with no confirmation (**ADR-0007**). "Auto" does not mean "ignore" — an Auto item still counts toward its **transfer line**, which means *"keep enough in this account for the debit to clear."*
- **Needs review** — the state of an Expense created automatically by an Auto item, until the owner confirms it. The only defence against a failed autodebit or a changed amount being recorded as fact.
- **Transfer line** — one row of the payday checklist: an Account, the sum of the plan's items paid from it, an optional **manual adjustment**, and whether the owner has made the transfer yet. Derived from the plan; reset each cycle. The adjustment is a one-off number inside one plan — the app never claims to know an Account's balance, and could not, since money also moves without passing through the app.
- **Group percentages** — the plan's allocation check: each Group's planned total as a share of **Total income**. Planned figures only; actual spend by Group is not shown here.

## Key decisions

- **Single-user, no auth.** Data is private to the owner's Apple ID via CloudKit; there is no server to run.
- **SwiftData + CloudKit constraints are accepted.** All model properties are optional-or-defaulted and there are **no enforced unique constraints**. Consequence: de-duplication of Category, Group, Person and Account is a **UI concern** — always pick from existing, and prompt on a case-insensitive name match rather than creating a duplicate (**ADR-0002**).
- **Deletes nullify, never cascade** (**ADR-0001**). Deleting a Category leaves its expenses **Uncategorized**; deleting a Person removes them from expenses; deleting an Account leaves its expenses **Unassigned**; deleting a PlanItem leaves its Expense intact. Expenses are never destroyed by deleting something that references them.
- **A plan is not a ledger** (**ADR-0005**). Analytics read Expenses only. A PlanItem never contributes to a spending total, so planned money can never be counted as spent.
- **Person covers recipients as well as companions** (**ADR-0006**), and the People leaderboard mixes them.
- **Money is `Decimal`, never `Double`.** Avoids floating-point drift in totals. Percentages are display-only and never stored.
- **Timestamps store date + time**, default to now at entry; only the date is surfaced in the v1 UI.

## Out of scope

Receipt photos · multi-currency · bank/CSV import · bill-splitting · widgets/Siri/App Intents · account balances, transfers between accounts, and reconciliation · income anywhere outside a cycle plan · net worth or cash-flow reporting.

Three items left this list with the cycle plan (`docs/prd/payday-planning.md`) and are now in scope **only in their plan-local form**: budgets (as **Envelope**), recurring expenses (as **carry-over** and **Auto**), and income tracking (as **Income line**). None of them exists outside a plan.

See `docs/prd/payday-planning.md` for the cycle-plan specification, `.scratch/expense-tracker-v1/spec.md` for the full v1 specification and `.scratch/expense-tracker-v1/design.md` for the accepted design. ADRs live in `docs/adr/`.
