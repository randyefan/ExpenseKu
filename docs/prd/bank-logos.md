# PRD — Bank logos for Accounts

Status: Built
Date: 2026-10-17 · design approved and built the same day (flow X)
Owner: Randy Efan

Companion documents: `CONTEXT.md` (**Account**, **Bank logo**), **ADR-0012** (the
read-only public catalog), and **`design/ExpenseKu.pen`**, page
`02 · Pages · iPhone`, **Flow X** (moved there from `05 · Proposals` once built). Frame references appear inline as `[→ X2]`.

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
- **Logos inside small glyphs.** Plan chips and Plan section headers keep an SF Symbol (§5).

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

### 5.2 Where

| Surface | Account with a logo |
|---|---|
| Manage › Accounts list | logo `[→ X4]` |
| Account picker (expense editor, plan item editor) | logo `[→ X5]` |
| Account editor stage | logo `[→ X2]` |
| Insights entity header | logo `[→ X6]` |
| Insights proportion rows (Spend by Account, a drill-in's breakdown) | `building.columns.fill`, bar in the brand tint `[→ X6]` |
| Filter sheet rows | logo |
| Expense row (every list that draws `ExpenseRow`) | 14pt mark under the amount, §5.5 `[→ X9 B, X10]` |
| Plan row chip, envelope detail chip | `building.columns.fill` `[→ X7]` |
| Plan section header (sorted by Account) | `building.columns.fill` `[→ X7]` |

### 5.3 Resolution

The mark is resolved every time it is drawn, never stamped on save, so a catalog change
reaches every Account that uses it.

| `brandID` | In the catalog? | Mark | Chip glyph |
|---|---|---|---|
| set | yes | logo | `building.columns.fill` |
| set | no — withdrawn or unknown | `building.columns.fill` in the Account's tint | `building.columns.fill` |
| nil | — | `iconName` ?? card glyph | `iconName` ?? card glyph |

`brandID` is kept when its logo is withdrawn, so adding the record back with the same
`id` restores the logo. `[→ X8]`

### 5.4 Colour

The Account's tint is its `colorHex` when set. When the colour is **Auto** and the logo
resolves, the tint comes from the catalog's `tint`, passed through the palette's pastel
recipe so it reads like the other swatches. Otherwise it comes from the name, as today.

### 5.5 The expense row

The Account moves out of the grey meta line and under the amount. `[→ X9 B]`

```
(icon) Makan                     Rp 85.000
       Lunch · Tarisa       (BCA) BCA Gaji
```

| Part | Content |
|---|---|
| Meta line | note · people — the Account is no longer in it |
| Trailing, line 1 | the amount, unchanged |
| Trailing, line 2 | the Account's mark at 14pt, then its name in caption grey, right-aligned |
| Trailing, line 3 | the date — Search only, as today `[→ X10]` |

- Every Account gets a mark on line 2: its logo, the bank glyph (§5.3), or its own symbol
  on its pastel wash.
- An expense with no Account (**Unassigned**) has no line 2; Search's date moves up.
- The Account's name is one line and truncates at its tail; the amount never truncates.
- VoiceOver reads the row in its visual order: tag, category, note · people, amount, account (and date in Search).
- Every list that draws `ExpenseRow` follows: the cycle List, the Month lens's day list,
  Search, and the Insights detail screens.

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

### 6.3 Snapshot

The app bundles a snapshot of the catalog: the same records, with their images in the
asset catalog.

| State | Catalog used |
|---|---|
| Never fetched (fresh install, offline) | bundled snapshot |
| Fetched at least once | the fetched catalog only — the snapshot is ignored |

The snapshot holds placeholders (the name's initials in the brand colour) for
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
- The expense filter's logic, the plan, transfer lines and every figure.
- The expense row's category icon, plan tag line, category name and amount.

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
| 7 | Logos replace icon circles only; chips and section headers use `building.columns.fill` | `X7` |
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
| 19 | Only Accounts **with** a logo get `building.columns` in Plan chips; others keep their symbol | `X7` |
| 20 | The expense row shows the Account **under the amount** with its mark — *owner override*, against inline in the meta line (C) | `X9 B` |
| 21 | Search keeps its date as a **third trailing line** — *owner override*, against moving it into the meta line | `X10` |

---

## 10. Design traceability

Page `02 · Pages · iPhone`, **Flow X · Bank logos for Accounts**. The unchosen expense-card options
A, C and D stay on `05 · Proposals`. `BankLogoMark` and the AccountIcon states are a specimen in
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

