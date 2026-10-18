# PRD — Bank logos for Accounts

Status: Accepted · §5.6 (the Plan lens, flow AA) amended 2026-10-18; §5.5 amended and built 2026-10-18 (flow Z, the bank leads the row)
Date: 2026-10-17 · design approved and built the same day (flow X); the expense row's mark enlarged the same evening (flow Y); the row led by the Account on 2026-10-18 (flow Z); the Plan lens's banks on 2026-10-18 (flow AA)
Owner: Randy Efan

Companion documents: `CONTEXT.md` (**Account**, **Bank logo**), **ADR-0012** (the
read-only public catalog), and **`design/ExpenseKu.pen`**, page
`02 · Pages · iPhone`, **Flows X, Y and Z** (moved there from `05 · Proposals` once built), and
**Flow AA** (frames AC1–AC4, on `05 · Proposals` until built). Frame references appear inline as `[→ X2]`.

---

## 1. What this is

An Account is drawn as a pastel circle holding an SF Symbol. Most of the owner's
Accounts are banks, and every one of them looks the same: a card glyph in a colour.

This feature lets the owner give an Account a **bank logo** picked from a list the
developer maintains. The list lives in CloudKit's public database, so a logo can be
added, replaced or withdrawn at any time without an app release.

## 2. Goals

1. Recognise a bank Account at a glance by its real logo.
2. Keep the Account's name the owner's own: picking a logo never renames it.
3. Let the developer change the list of logos at any time; every device follows on its
   next launch or return to the foreground.
4. Never leave an Account without a mark: offline, before the first download, or after a
   logo is withdrawn, it still draws.

## 3. Non-goals

- **Logos for Categories, Groups or People.** Account only.
- **Matching a logo from the Account's name.** The owner picks; nothing is suggested.
- **Uploading a logo from the device.** The list is the developer's.
- **An e-wallet section.** E-wallets go in the same Banks list; DANA is the first, added
  because the owner has a DANA Account. Others can be added to the catalog without code.
- **Instant push.** No CloudKit subscription; the next launch or foreground is enough.
- **Logos inside small glyphs.** Insights' proportion rows keep an SF Symbol (§5.2). *Plan chips and
  Plan section headers kept one too until 2026-10-18; §5.6 gives them the wordmark.*

---

## 4. Picking a logo

The Account editor's **Icon** pane gains a **Banks** section, after *From the name* and
before the SF Symbol groups. `[→ X1]`

| Choice | Stored | Stage shows | Caption |
|---|---|---|---|
| Auto (From the name) | `brandID = nil`, `iconName = nil` | card glyph | "… automatic icon" |
| A symbol | `brandID = nil`, `iconName = symbol` | the symbol | "… custom icon" |
| A bank logo | `brandID = id`, `iconName = nil` | the logo `[→ X2]` | "… bank logo" |

- One slot: picking a logo clears the icon, and picking a symbol or Auto clears the logo.
- Logos are ordered by the catalog's `sortOrder`, then `displayName`.
- The icon search also matches a logo's `displayName` (`localizedStandardContains`).
  "bca" shows the BCA logo and no symbols. `[→ X3]`
- The **Banks** section is hidden when the catalog is empty.
- The stage's shuffle button picks colours and symbols only, never a logo.
- The Category and Group editors have no Banks section.

## 5. Drawing an Account

### 5.1 The logo mark

A logo is drawn in a **white circle** the size of the icon circle it replaces, the logo
centred with padding so a wide wordmark fits. It is never tinted. `[→ X2, X4]`

The padding is 19% of the diameter. Every catalog logo is a wide wordmark centred in a square
image, so the padding decides how tall its letters get; a small mark takes a thinner one (§5.5).

### 5.2 Where

| Surface | Account with a logo |
|---|---|
| Manage › Accounts list | logo `[→ X4]` |
| Account picker (expense editor, plan item editor) | logo `[→ X5]` |
| Account editor stage | logo `[→ X2]` |
| Insights entity header | logo `[→ X6]` |
| Insights proportion rows (Spend by Account, a drill-in's breakdown) | `building.columns.fill`, bar in the brand tint `[→ X6]` |
| Filter sheet rows | logo |
| Expense row (every list that draws `ExpenseRow`) | 42pt leading mark with a category badge, §5.5 `[→ ZA1–ZA4]` |
| Plan row chip, envelope detail chip | wordmark plate + name in the grey chip, §5.6 `[→ AC2, AC4]` |
| Plan section header (sorted by Account) | 60×28 wordmark plate, total and state, §5.6 `[→ AC1]` |
| Transfer checklist line | 60×28 wordmark plate leads the line, §5.6 `[→ AC3]` |

### 5.3 Resolution

The mark is resolved every time it is drawn, never stamped on save, so a catalog change
reaches every Account that uses it.

| `brandID` | In the catalog? | Mark | Chip glyph | Plate (§5.6) |
|---|---|---|---|---|
| set | yes | logo | the wordmark | the wordmark on white |
| set | no — withdrawn or unknown | `building.columns.fill` in the Account's tint | `building.columns.fill` | `building.columns.fill` on the Account's wash |
| nil | — | `iconName` ?? card glyph | `iconName` ?? card glyph | `iconName` ?? card glyph on the Account's wash |

`brandID` is kept when its logo is withdrawn, so adding the record back with the same
`id` restores the logo. `[→ X8]`

### 5.4 Colour

The Account's tint is its `colorHex` when set. When the colour is **Auto** and the logo
resolves, the tint comes from the catalog's `tint`, passed through the palette's pastel
recipe so it reads like the other swatches. Otherwise it comes from the name, as today.

### 5.5 The expense row

*Amended 2026-10-18 (flow Z, option A). Until then the row led with its category and drew the
Account as a 22pt mark under the amount (decisions 20 and 22).*

The Account leads the row. Its mark takes the place of the category icon, and the category
rides on the mark's corner as a badge. `[→ ZA1]`

```
(BCA)  Makan                     Rp 43.000
(  ●)  Makan siang · Tarisa       BCA Gaji
```

| Part | Content |
|---|---|
| Leading mark | the Account's mark at 42pt: its logo in a white circle with 12% padding, the bank glyph (§5.3), or its own symbol on its pastel wash `[→ ZA1]` |
| Category badge | an 18pt circle filled solid in the category's tint with its glyph in ink (`on-tint`), ringed 1pt in the card colour, on the mark's lower-right corner and hanging 4pt past it `[→ ZA1]` |
| Text column | plan tag line, category name, note · people — unchanged |
| Trailing, line 1 | the amount, unchanged |
| Trailing, line 2 | the Account's name in caption grey, right-aligned, one line, truncating at its tail; no mark `[→ ZA1]` |
| Trailing, line 3 | the date — Search only, as before `[→ ZA2]` |

| Expense | Leading mark | Badge | Trailing line 2 |
|---|---|---|---|
| Account with a logo | the logo | category | Account name |
| Account without a logo, or its logo withdrawn | the Account's symbol, or the bank glyph (§5.3) | category | Account name |
| No Account (**Unassigned**) | the category icon at 42pt | none | none — Search's date moves up |
| Uncategorized, with an Account | the Account's mark | `tag` glyph in the name-seeded tint | Account name |

- **Insights › one Account** keeps the category-first row: every row there would carry the same
  logo, which the screen's header already shows. Its rows lead with the 42pt category icon, with no
  badge and no Account name. `[→ ZA3]`
- Every other list that draws `ExpenseRow` follows: the cycle List, the Month lens's day list,
  Search, Person detail, the Category and Group drill-ins, Envelope detail, and the Move sheet. In
  Select mode the selection circle stays left of the mark. `[→ ZA4]`
- The mark and badge scale with Dynamic Type, relative to body. The mark sits 14pt from the text
  column (12pt before), so the badge's overhang never touches the text; the separator starts after
  the mark.
- The Account name's 130pt cap scales with Dynamic Type, relative to caption. The amount never
  truncates.
- VoiceOver reads the row as before: tag, category, note · people, amount, account (and date in
  Search). The mark and the badge are hidden from it.
- At 42pt with 12% padding a wordmark is ~31pt wide and its letters ~7pt tall (~5pt at 22pt).
  A row whose meta line is one line is ~62pt, against 65pt with the mark under the amount.

### 5.6 The Plan lens

*Amended 2026-10-18 (flow AA: option C, the Transfer checklist in C's style, and option A's chip).
Until then a bank Account wore `building.columns.fill` in plan chips and Account headers
(decisions 7 and 19), and the checklist line was text only.*

A bank shows in the Plan lens as its **wordmark**: the catalog logo cropped to the pixels that
carry ink (`LogoTrim`), on white. Every catalog logo is a wide wordmark centred in a square
image, so a landscape plate shows its letters about three times taller than a circle of the
same height.

#### 5.6.1 The plate

| Account | Plate |
|---|---|
| Logo resolves | the cropped wordmark, fitted with padding, on a white rounded rectangle `[→ AC1]` |
| No logo (Cash, a brandless GoPay) | the Account's own symbol on its pastel wash, the same shape `[→ AC1]` |
| Logo withdrawn or unknown (§5.3) | `building.columns.fill` on the Account's wash |
| **Unassigned** (no Account) | `creditcard` on a grey wash `[→ AC1]` |

The plate is **60×28** in the section header and the checklist line, and scales with Dynamic
Type relative to body. It is hidden from VoiceOver: the name is always read beside it.

#### 5.6.2 Sorted by Account — the bank heads its group

When the plan is sorted by **Account** (plan-sort.md §4), each group's header becomes a bank
header. `[→ AC1]`

```
[ BNI  ]  BNI                  Rp 7.706.000
          1 item                 all in BNI
```

| Part | Content |
|---|---|
| Leading | the plate (§5.6.1) |
| Line 1 | the Account's name (Unassigned for none), body, bold |
| Line 2 | the count (§5.6.5), caption grey — no due days |
| Trailing, line 1 | the group's **total**: the sum of its items' amounts, as the rows below show them — not the transfer line's net figure |
| Trailing, line 2 | the group's **state**, caption |

The state reads the items' effective states (payday-planning.md §7.6), the same three the
leading check draws:

| Items in the group | State | Colour |
|---|---|---|
| every one Todo ◯ | `nothing in yet` | caption grey |
| some Todo, some Funded or Done | `Rp X to go` — X is the sum of the Todo items | caption grey |
| none Todo, at least one Funded ◐ | `all in BNI` — the Account's name | accent |
| every one Done ✓ | `all paid` | positive green |

- Envelopes and Auto items follow the same rule: a Funded Envelope is in its Account, a Funded
  Auto item's Account covers the debit. An Envelope never reaches Done, so a group holding one
  never reads `all paid`.
- A set-aside line is Todo until moved, then Done (set-aside.md §4.4).
- **Unassigned** can never be Funded, so its state is only `Rp X to go` (every item Todo
  included) or `all paid`.
- The Transfer checklist's ✓ Sent does not move the state: it is about the Account, not an
  item (CONTEXT.md **Funded**).
- With the Plan filter on (plan-filter.md), the header counts, totals and states the items it
  shows.
- VoiceOver reads the header as one element: "BNI, 1 item, Rp 7.706.000, all in BNI".

**Rows inside a bank group drop their Account chip, and a Funded row drops its trailing
`in BNI`** — the header says both once. An Envelope with an Account loses the chip line that
named it. Supersedes plan-sort.md §4.2 "Rows do not change" and its non-goal "Subtotals in group
headers", for the Account order only. `[→ AC1]`

The Group and Status orders keep their headers (plan-sort.md §4.2).

#### 5.6.3 Every other order — the wordmark chip

In Amount, Due day, Group, Status and Name order, and with the Funded filter (which forces
Amount), a plan row's Account chip stays the **grey chip**; a bank Account's glyph becomes a
small white **wordmark plate**, followed by the Account's name. `[→ AC2]`

```
Kos                          Rp 2.200.000
( Sewa ) ( [BCA] BCA ) ( Due 1 )
```

- The name always follows the plate, even when no other Account shares the bank — *owner
  override* of showing it only for two Accounts at one bank.
- **When the chip line does not fit on one line**, the Account chip drops its name and keeps the
  plate alone, before anything else gives way. In the sample this happens to Cicilan Rumah BNI
  (Cicilan · BNI · Due 5 · Auto · in BNI), Cicil ke Kartu Kredit and Netflix. `[→ AC2]`
- The plate is white, 15pt tall inside the chip (the chip's text height plus 1.5pt above and
  below), its width set by the wordmark plus 4pt each side, with a 4pt corner; it scales with
  the chip's Dynamic Type. The chip's leading padding shrinks to 4pt so the plate sits close to
  its edge.
- An Account without a logo keeps its own symbol; a withdrawn logo shows `building.columns.fill`
  (§5.3), as before.
- The same chip is drawn wherever a plan chip names an Account: Fixed, Envelope and set-aside
  rows, and the Envelope detail sheet's card. `[→ AC4]`
- VoiceOver reads the chip as the Account's name, as before.

#### 5.6.4 The Transfer checklist

Each line leads with the Account's plate, after the ✓ Sent check, and is named by the Account
without `ke`. `[→ AC3]`

```
◯  [ BNI  ]  BNI                       Rp 7.706.000
             1 item · Due 5 · Auto debit —
             keep this covered
◯  [Danmn ]  CC Danamon                Rp 4.830.000
             2 items · Due 12, 20
```

| Part | Content |
|---|---|
| Check | ✓ Sent, unchanged |
| Plate | §5.6.1, 60×28 like the header's |
| Line 1 | the Account's name — `ke` dropped — and, trailing on the same line, the amount transferred |
| Line 2 | the count (§5.6.5) · `Due` and the due days, then the notes the line already carried — the adjustment, paid early / set aside, `Auto debit — keep this covered` — joined by ` · `, at most two lines, running under both the name and the amount |

- Due days come from the line's items that have one, in cycle order (plan-sort.md §4.1), each
  day once; after three, `…`. No dated item: no `Due` part.
- The order of the lines, the tap targets (check → Sent, the rest → adjustment editor) and the
  VoiceOver label "Transfer to BNI" are unchanged. Every Account with money against it has a
  line, the one the salary lands in included (AC3 draws BCA, which the options left out).

#### 5.6.5 The count

| Items | Reads |
|---|---|
| no Envelopes | `1 item`, `2 items` |
| only Envelopes | `1 envelope`, `2 envelopes` |
| both | `1 item, 1 envelope` |

A set-aside line counts as an item. The header and the checklist use the same words.

## 6. The catalog

### 6.1 Records

Record type `BankLogo` in the public database of `iCloud.randyefan.ExpenseKu`:

| Field | Type | Meaning |
|---|---|---|
| `id` | String | the stable key stored in `Account.brandID`, e.g. `bca` |
| `displayName` | String | label, search text and accessibility label |
| `logo` | Asset | PNG, at least 256×256, transparent background |
| `tint` | String | `RRGGBB` brand colour |
| `sortOrder` | Int64 | position in the Banks section |

The developer edits these in CloudKit Console. The app only reads.

### 6.2 Sync

- The app fetches the **whole** catalog on launch and on return to the foreground, at most
  once every 10 minutes. A public-database query cannot report deletions, so a delta
  fetch would never notice a withdrawn logo; the list is a few dozen records.
- A logo asset is downloaded only when its record changed since the cached copy.
- The fetched list and its images are cached on device and survive relaunch.
- A failed fetch keeps the last good catalog.

### 6.2.1 Logo sources

The images are the banks' own logos as published on Wikimedia Commons, rendered to PNG,
trimmed and fitted to a 256×256 transparent square (2026-10-17). They are trademarks of their
banks, shown only to mark the owner's own Accounts (ADR-0012).

| id | Commons file | Licence on Commons |
|---|---|---|
| bca | Bank Central Asia.svg | Public domain |
| bri | BRI 2025 (symbol).svg — the symbol alone; the wordmark is too wide | Public domain |
| bni | Bank Negara Indonesia logo (2004).svg | Public domain |
| mandiri | Bank Mandiri logo 2016.svg | Public domain |
| bsi | Bank Syariah Indonesia.svg | Public domain |
| jago | Bank Jago 2026.svg | Public domain |
| seabank | SeaBank.svg (Indonesia, not Vietnam's SeABank) | Public domain |
| cimb-niaga | CIMB Niaga logo.svg | Public domain |
| danamon | Danamon (2024).svg | Public domain |
| superbank | Superbank.svg | Public domain |
| dana | Dana-meta-logo.png | CC BY-SA 4.0 — credit "DANA logo, Wikimedia Commons, CC BY-SA 4.0" if the app is ever distributed |

### 6.3 Snapshot

The app bundles a snapshot of the catalog: the same records, with their images in the
asset catalog.

| State | Catalog used |
|---|---|
| Never fetched (fresh install, offline) | bundled snapshot |
| Fetched at least once | the fetched catalog only — the snapshot is ignored |

The snapshot holds the official logos (§6.2.1; until 2026-10-17 they were placeholders) for
**BCA, BRI, BNI, Mandiri, BSI, Bank Jago, SeaBank, CIMB Niaga, Danamon, Superbank, DANA**, in
that order, with ids `bca, bri, bni, mandiri, bsi, jago, seabank, cimb-niaga, danamon,
superbank, dana` and sortOrder 10 to 110. Danamon, Superbank and DANA were added on 2026-10-17
so every one of the owner's own Accounts has a logo; DANA is an e-wallet, listed under Banks. Official logos replace them in
CloudKit Console and in the asset catalog.

## 7. Lifetime

| Event | Effect |
|---|---|
| Owner picks a logo | `brandID` saved on the Account, synced privately like its colour |
| Relaunch | cached catalog drawn at once, refreshed in the background |
| Developer replaces a logo | every Account using it redraws after the next fetch |
| Developer withdraws a logo | §5.3 fallback; `brandID` kept |
| Developer adds a logo | appears in the Banks section after the next fetch |
| Account deleted | nothing — the catalog is not touched |

## 8. Unaffected

- Category, Group and Person editors and marks.
- Account names, de-duplication (ADR-0002) and delete rules (ADR-0001).
- The expense filter's logic, the plan, transfer lines and every figure — §5.6 only draws them.
- Plan sort's orders, the Group and Status headers, the Funded notice and filter.
- The expense row's plan tag line, category name, meta line and amount.

---

## 9. Decision log

Settled in a grilling session on 2026-10-17. Entries 17–21 were settled when the owner
reviewed flow X the same day and asked for the expense row to be redesigned with it.

| # | Decision | Drawn in |
|---|---|---|
| 1 | The catalog lives in CloudKit's **public database**, edited in Console; the app only reads (ADR-0012) | — |
| 2 | Sync on launch and foreground, at most every 10 minutes, fetching the **whole** catalog (a delta fetch cannot see deletions); no push subscription | — |
| 3 | `Account.brandID: String?`; logo and `iconName` share one slot | `X1`, `X2` |
| 4 | The Account's name stays the owner's; nothing is suggested from it | `X2` |
| 5 | Logos are a **Banks** section in the Icon pane, not a third segment | `X1` |
| 6 | The logo sits in a **white circle**, the size of the icon circle | `X2`, `X4` |
| 7 | Logos replace icon circles only; chips and section headers use `building.columns.fill` — *superseded by 32* | `X7` |
| 8 | A withdrawn logo falls back to `building.columns.fill`; `brandID` is kept | `X8` |
| 9 | A bundled snapshot covers the time before the first fetch | — |
| 10 | The first images are placeholders | `X1` |
| 11 | The first list is eight banks: BCA, BRI, BNI, Mandiri, BSI, Bank Jago, SeaBank, CIMB Niaga; Danamon, Superbank and DANA added the same day to cover every Account the owner has — *owner override* of the e-wallet non-goal for DANA | `X1` |
| 12 | Auto colour takes the logo's `tint` | `X2` |
| 13 | Shuffle never picks a logo | — |
| 14 | Search matches a logo's `displayName` | `X3` |
| 15 | The section is titled **Banks**; the caption says **bank logo** | `X1`, `X2` |
| 16 | Its own PRD, plus ADR-0012 | — |
| 17 | Bank tiles in the picker are the icon tile with a 30pt logo inside | `X1` |
| 18 | The logo circle is pure white with no outline | `X4` |
| 19 | Only Accounts **with** a logo get `building.columns` in Plan chips; others keep their symbol — *superseded by 32; a logo-less Account still keeps its symbol* | `X7` |
| 20 | The expense row shows the Account **under the amount** with its mark — *owner override*, against inline in the meta line (C) | `X9 B` |
| 21 | Search keeps its date as a **third trailing line** — *owner override*, against moving it into the meta line | `X10` |
| 22 | The row's mark grows to a **22pt circle with 8% padding** (option A) — *owner override*, against a white wordmark chip beside the name (B); badge on the category icon (C) and logo-only chip (D) not chosen | `Y A` |
| 23 | The **Account leads the expense row**; the category becomes a badge on its mark (flow Z option A; B–H not chosen). Supersedes the mark under the amount (20, 22) | `ZA1` |
| 24 | The leading mark is **42pt**, the badge 20pt with its ring | `ZA1` |
| 25 | An Account without a logo leads with its **own symbol** circle and the badge, so the leading mark is always the Account | `ZA1` |
| 26 | The trailing line keeps the **Account name**, without a mark | `ZA1` |
| 27 | An expense with **no Account** leads with its category icon at 42pt, no badge | `ZA1` |
| 28 | The badge is the category tint **solid**, glyph in ink | `ZA1` |
| 29 | **Insights › one Account** keeps the category-first row, without the Account name | `ZA3` |
| 30 | This is an amendment of §5.5, not its own PRD | — |
| 31 | Approved at the design gate: the 14pt gap between mark and text; the Uncategorized badge takes the name-seeded tint; ZA3's header is drawn simplified (the Insights header itself is unchanged) | `ZA1`, `ZA3` |
| 32 | The Plan lens shows banks by their **wordmark** (flow AA: C for the Account order, C's style for the checklist, A's chip elsewhere; B, D, E, F not chosen). Supersedes 7 and 19 | `AC1`–`AC3` |
| 33 | Sorted by Account, the header carries a 60×28 plate, the name, the count, the group's total and its **state** | `AC1` |
| 34 | The state has four cases: `nothing in yet`, `Rp X to go` (X = the Todo items), `all in BNI`, `all paid`; Envelopes and Auto items follow the same rule | `AC1` |
| 35 | The chip in other orders always carries the **name after the wordmark** — *owner override*, against the name only when two Accounts share a bank | `AC2` |
| 36 | The chip stays **grey** with a small white wordmark plate inside, not a white pill | `AC2` |
| 37 | The checklist line drops `ke`; line 2 is the count · due days, then the existing notes | `AC3` |
| 38 | An Account without a logo gets a **plate on its pastel wash** with its own symbol | `AC1`, `AC3` |
| 39 | **Unassigned** gets a grey plate with `creditcard`; its state is only `Rp X to go` or `all paid` | `AC1` |
| 40 | The header's total is the **sum of its items**, not the transfer line's net figure | `AC1` |
| 41 | Inside a bank group rows drop the Account chip **and** the Funded `in BNI` | `AC1` |
| 42 | **Every** plan Account chip takes the wordmark: Fixed, Envelope, set-aside rows and the Envelope detail card | `AC4` |
| 43 | The count names Envelopes apart: `2 items`, `1 envelope`, `1 item, 1 envelope`; due days (checklist only) in cycle order, at most three then `…` | `AC1`, `AC3` |
| 44 | An amendment of this PRD (§5.6), not its own | — |
| 45 | Chosen without asking, confirmed at the grill's gate: the header shows no due days; `all in` in the accent and `all paid` in the positive green, the rest grey; a withdrawn logo's plate is the bank glyph on its wash; the plate scales with Dynamic Type; the checklist's ✓ never moves the header's state; the Plan filter's header counts what it shows | `AC1` |
| 46 | Approved at the design gate: a chip line that does not fit drops the Account chip's **name**, keeping its plate; the checklist's amount moves to the name's line so its note runs full width; the checklist plate is 60×28; the chip's plate is white, 15pt, 4pt corner; other orders keep `in BNI` and the Envelope detail keeps `in Jago`; Cash keeps its symbol in the chip | `AC2`, `AC3`, `AC4` |

---

## 10. Design traceability

Page `02 · Pages · iPhone`, **Flow X · Bank logos for Accounts**. The unchosen expense-card options
A, C and D stay on `05 · Proposals`, as do flow Y's options B, C and D (the shipped 14pt row is kept
there for comparison). `BankLogoMark` and the AccountIcon states are a specimen in
`01 · Design System`, group `Primitives`; the `ExpenseRow` component carries the Account line.

| Frame | Covers |
|---|---|
| BankLogoMark · the eight placeholder marks | §5.1, §6.3 |
| **X1** · Account editor, Icon pane — the Banks section | §4, decisions 5, 10, 11, 15 |
| **X2** · BCA picked — stage, caption, auto colour | §4 table, §5.1, §5.4 |
| **X3** · Searching "bca" | §4 search |
| **X4** · Manage › Accounts — logos beside icons | §5.2 |
| **X5** · Account picker in the expense editor | §5.2 |
| **X6** · Insights › an Account — the entity header | §5.2 |
| **X7** · Plan sorted by Account — chips and headers | §5.2, decision 7 |
| **X8** · A withdrawn logo — the bank glyph fallback | §5.3, decision 8 |
| **X9** · Expense card options A–D — **B chosen** | §5.5, decision 20 |
| **X10** · Search results — three trailing lines | §5.5, decision 21 |
| **Y A** · The Today card with a 22pt mark — option A, chosen; superseded by Z | §5.1, decision 22 |
| **Z A–H** · Bank-forward list directions, left on `05 · Proposals` — A chosen and built as Flow Z on page 02 | decision 23 |
| **AA Now, A–F** · Plan-lens directions, left on `05 · Proposals` — C (with A's chip) chosen | decision 32 |
| **ZA1** · The cycle List: logos, a symbol Account, Unassigned, Uncategorized, a withdrawn logo | §5.5, decisions 23–28 |
| **ZA2** · Search results — the date under the Account name | §5.5 |
| **ZA3** · Insights › BCA Gaji — category-first rows | §5.5, decision 29 |
| **ZA4** · Select mode — the selection circle before the mark | §5.5 |
| **AC1** · Plan sorted by Account — bank headers, Cash's plate, Unassigned, the four states | §5.6.1, §5.6.2, decisions 33, 34, 38–41 |
| **AC2** · Plan sorted by Amount — the wordmark chip with the name | §5.6.3, decisions 35, 36 |
| **AC3** · Payday Transfer checklist — plates, counts, due days, notes | §5.6.4, §5.6.5, decisions 37, 43 |
| **AC4** · Envelope detail — the wordmark chip on its card | §5.6.3, decision 42 |

### 10.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| Insights' proportion rows draw a bare 16pt glyph, not a circle | Treated like a chip: `building.columns.fill`, the bar in the brand tint | `SpendSummary.byAccount`, `SpendBreakdownCard`, `SpendByAccountChart` |
| `UIImage` cannot load a PDF from a file | The catalog's image is PNG only | `BankLogoStore` |
| A record with no image | Left out of the fetched catalog rather than drawn blank | `BankLogoCatalog.refreshIfDue` |
| An id is also the cache file name | Only lowercase slug ids (`a–z`, `0–9`, `-`) are used | `BankLogoRules.isUsable` |
| After a fetch withdrew Mandiri, its row drew an empty white circle | The id lookup is observed, so marks redraw when the catalog changes; a missing image draws a grey bank glyph | `BankLogoCatalog`, `BankLogoTests.testALookupIsToldWhenAFetchChangesIt` |
| The unsigned test host has no CloudKit entitlement | Under XCTest the catalog is the snapshot with no source | `BankLogoCatalog.live()` |
| A long Account name would squeeze the note | The name is capped at a Dynamic-Type-scaled 130pt and truncates | `ExpenseAccountLabel` |
| A Category drill-in narrowed to one Account lists one Account's rows too (flow Z) | Treated like Insights › one Account: the category-first row | `ExpenseRowLead.accountsLead(subject:narrowing:)`, `ExpenseRowLeadTests` |
| ZA1 draws the badge as an 18pt fill in a 20pt card-coloured frame (flow Z) | The ring is 1pt, not 2pt, and the badge hangs 4pt past the mark's corner | `ExpenseRowMark` |
| Person detail's hand-drawn divider was inset by the old 38pt icon (flow Z) | It insets by the scaled 42pt mark + 14 | `PersonDayCard` |
| At extra-extra-large text the category name truncates beside a wide amount (flow Z) | Pre-existing (the amount takes the width); the 42pt mark narrows the column a little more. Left as is | — |
| With Auto colour, the colour pane's Auto swatch showed the name's tint | Auto shows the brand's tint when a logo is chosen | `ColorWorkbench.autoHex` |

### 10.2 Owner setup in CloudKit Console

1. In the **Development** environment of `iCloud.randyefan.ExpenseKu`, create record type `BankLogo`
   with fields `id` (String), `displayName` (String), `logo` (Asset), `tint` (String),
   `sortOrder` (Int64).
2. Add an index: `recordName` → **Queryable** (the fetch queries every record).
3. Security roles for `BankLogo`: `_world` can **Read**; only the developer creates and writes.
4. Add the eleven records with the snapshot's ids and order (`bca` 10 … `dana` 110) and their
   logos. Done in Development on 2026-10-17 with the placeholder images; `_icloud` lost its
   default Create on `BankLogo` so no iCloud user can add to the shared list.
5. **Deploy Schema Changes** to Production, which also deploys `CD_Account.CD_brandID`. Records are
   per environment: add the logos in Production too.

Done on 2026-10-17. Production had no schema at all before this deploy, so the private-database
sync of every earlier TestFlight build had nothing to write to. The Development schema lagged the
models by six fields that no debug build had synced yet; they were added by hand as STRING (the
type Core Data uses for strings and to-one relationships) before deploying: `CD_Account.CD_brandID`,
`CD_Category.CD_group`, `CD_CategoryGroup.CD_colorHex` and `CD_iconName`, `CD_Person.CD_colorHex`,
`CD_PlanItem.CD_setAsideTarget`. The eleven `BankLogo` records exist in both environments with the
placeholder art. A future model attribute needs the same check: compare the Deploy dialog's Diff
View with the models before deploying.

