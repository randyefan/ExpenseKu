# PRD — Reading receipts

Status: Built
Date: 2026-11-08 · grilled, drawn (flow AG), approved and built the same day as the on-device spike (`.scratch/receipt-ai/`), on `feature/receipt-reading`, not merged until the owner says so
Owner: Randy Efan

Companion documents: `CONTEXT.md` (ubiquitous language), `docs/prd/quick-entry-form.md`
(the expense form this fills), **ADR-0014** (receipts read on the device, photos kept only
until checked), and the **Wonder file "ExpenseKu"** (org `randy-efan`), page
`05 · Proposals — not built`, **Flow AG**. The first flow drawn in Wonder: the design
moved there from `design/ExpenseKu.pen` on 8 Nov 2026. Frame references appear inline as `[→ AG2]`.

---

## 1. What this is

After a transfer the owner has a receipt image in the banking app (BCA, Superbank,
Danamon, Jago…), and after shopping a paper receipt. Today every figure on it is typed
into the expense form by hand.

This feature reads the receipt on the iPhone, offline, and fills the expense form from it.
A receipt reaches the app two ways:

- **Shared** from the banking app (or Photos) to ExpenseKu. It waits in a **receipt
  inbox** until the owner opens the app.
- **Read** from inside the expense form: Photos, Camera, or Paste.

The form is filled silently; the owner still saves it with ✓. An expense saved from a
receipt is marked **Needs review** and keeps its receipt image until the owner checks it.

How it reads (proved in the spike, 8 Nov 2026): Vision OCR → code lists every money
value, date and bank on the receipt as **candidates** → Gemma 4 E2B, running on the phone,
picks which candidate is the amount, the fee, the date, the bank and the counterparty,
and which of the owner's Categories fits → code accepts a pick only when it equals a
candidate. **The model can never invent a number.** Without the model, code rules fill
what they are sure of.

## 2. Goals

1. A transfer shared from a banking app becomes a saved expense in: open ExpenseKu →
   tap the inbox banner → pick a Category if needed → ✓.
2. Nothing is read by a server. OCR and the model run on the phone; the only network
   call is the one-time model download.
3. A wrong reading is caught later, not saved as fact: every receipt expense is marked
   Needs review, with its image, until checked.

## 3. Non-goals

- **Saving an expense from the share sheet itself.** The share sheet only stores the
  receipt (§4.1). The store stays where it is; it does not move to an App Group.
- **Opening ExpenseKu from the share sheet.** iOS has no supported way; the owner opens
  the app.
- **Detecting transfers to the owner's own accounts.** A receipt to "Randy Efan Jaya
  Putra" fills like any other — *owner override* (decision 8).
- **Line items.** One receipt is one Expense with the receipt's total.
- **Creating People.** A counterparty only ever matches an existing Person.
- **iPad and macOS.** The share extension and the model ship on iPhone. The receipt
  image, Needs review, the Check tag and the review sheet sync and show everywhere.
- **Voice entry.** Parked by the owner.
- **Choosing a model.** Gemma 4 E2B only.

---

## 4. The rules

### 4.1 Sharing a receipt — the inbox `[→ AG1, AG2]`

- ExpenseKu appears in the share sheet for **images** and **PDFs** (the first page is
  read). Text shares are not accepted.
- The share sheet shows a small card: the receipt thumbnail, **"Saved to ExpenseKu"**,
  **"Open ExpenseKu to log it."**, and **Done**. It reads nothing and touches no data.
- A receipt whose image is **byte-identical** to one already waiting is not added
  again; the card still says "Saved" (it is).
- Waiting receipts live **on this device only** (an App Group folder), oldest first,
  until each is saved as an expense or discarded. They never sync.

### 4.2 Banners on the Expenses tab `[→ AG2]`

Two banners sit in **one card** under the lens toggle, above the tab's content, in
**every lens** (List, Month, Plan), inbox first, split by a hairline. Each row is a
Manage-style row: a 38 pt icon circle, a title, a caption, a chevron. The inbox row's
icon is a receipt on the amber wash; the review row's is a clipboard-check on `surface`.
Captions: "Shared to ExpenseKu on this iPhone" and "Saved from a receipt, not checked yet".

| Banner | Shows when | Count | Tap |
|---|---|---|---|
| **🧾 N receipts waiting ›** | the inbox is not empty | waiting receipts on this device | opens the form for the oldest (§4.5) |
| **N from receipts to check ›** | an expense is Needs review **from a receipt** | over every cycle, ignoring the expense filter and the plan filter | opens the review sheet (§4.8) |

A banner with a count of 0 is not drawn. Auto items' Needs review stays in the Plan lens
and is not counted here (§6).

### 4.3 Reading from the form `[→ AG3]`

- The expense form's navigation bar gets **Read receipt**, a round glass button with a
  receipt glyph at the trailing edge (the form has no other toolbar item; ✓ stays on the
  keypad). It is a Menu, in this order: **Photos**, **Camera**, **Paste**. `[→ AG3]`
  - Photos: the system photo picker, one image.
  - Camera: the system document camera, which straightens and crops; the first page is
    read.
  - Paste: disabled unless the pasteboard holds an image.
- It is offered on Add and on Edit.
- While reading, the form dims and shows a centred card: a spinner, **"Reading receipt…"**,
  and **Cancel** `[→ AG3b]`;
  the keypad and fields do not take input until it finishes. Cancel leaves the form as
  it was.

### 4.4 Filling the form `[→ AG4]`

The reading fills **only fields still empty or at their default**. A value the owner
typed or chose is never replaced.

| Field | Filled with | Counts as empty when |
|---|---|---|
| Amount | the receipt's amount; with a fee, the expression **`amount+fee`** on the keypad, so the saved amount is what left the account and the fee is one ⌫ away | the amount is 0 |
| Date & time | the receipt's date and time; a receipt date with no time keeps the form's clock time | the date is still the moment the form opened (Now) and was not preset |
| Account | the Account wearing the receipt bank's logo (`brandID`); several → the most used in the last 90 days; none → **None** | still the form's default Account |
| Note | the counterparty or shop, as printed ("MUHAMMAD FADHIL", "INDOMARET") | empty |
| People | adds the one existing Person whose name equals the counterparty, or equals its leading words ("Salsabila" for "Salsabila Arum Lukit"), ignoring case; zero or several matches → nothing added | always additive; Me stays |
| Category | Gemma's pick from the owner's Category names | no Category chosen |
| Envelope | untouched | — |

- The form is filled **silently**: no card, no badge, no highlight — *owner override*
  (decision 6). The only sign is the filled values themselves.
- A field the reading could not settle stays as it was. Amount 0 or no Category still
  blocks Save, as today.

### 4.5 The inbox, one receipt after another `[→ AG2, AG4, AG5]`

- Tapping the inbox banner reads the oldest waiting receipt and opens **Add Expense**
  filled from it. The navigation title carries **"Receipt 1 of 3"** as its subtitle.
- ✓ saves the expense, removes the receipt from the inbox, and opens the next one
  directly, until the inbox is empty.
- Cancel asks, as a confirmation dialog titled "Receipt 1 of 3" with the message
  "Discard this receipt, or keep it in the inbox for later?": **Discard receipt**
  (destructive, removes it), **Later** (keeps it, stops the run), and **Keep editing**
  (the cancel button, back to the form). This replaces the form's usual discard-changes
  question.

### 4.6 Looks already logged `[→ AG6]`

After reading and before the form opens (inbox) or fills (Read receipt), if an Expense
already exists with the **same amount** (the receipt's amount, or amount + fee) on the
**same calendar day** as the receipt's date, a dialog asks:

- title **"Looks already logged"**, message naming that expense ("Rp 62.500 · Sat 22 Aug
  · MUHAMMAD FADHIL");
- **Discard receipt** / **Log anyway** (inbox), **Don't fill** / **Fill anyway**
  (Read receipt).

A receipt with no amount or no date is never checked.

### 4.7 Saving — Needs review `[→ AG2]`

- An expense saved with **any field filled from a receipt** is saved with
  `needsReview = true` and the receipt image attached (`Expense.receiptImage`, schema
  V8). This holds on Edit too.
- Its row shows a small **Check** capsule (accent text on the accent wash) after the
  Category name, wherever an expense row
  is drawn (List, Search, an envelope's detail).
- The flag and the image clear together, by any of:
  - **Looks right** in the review sheet;
  - opening the expense and tapping ✓, changed or not;
  - **Mark as checked** in the row's long-press menu.
- Deleting the expense deletes its image with it.

### 4.8 The review sheet `[→ AG7]`

- **"To check (N)"**, one card per receipt expense, oldest first.
- A card: the receipt image on the leading side (tap → full screen, pinch to zoom) and
  what was saved on the trailing side — amount, date and time, Account, Category, note.
- **Edit** (a `surface` button) opens the expense form; **Looks right** (the accent
  button) clears the flag and the image, and the card leaves. The sheet closes with ✕.
- The sheet closes itself when the last card leaves.

### 4.9 Without the model — rules `[→ AG4]`

Before the model is downloaded, after it is removed, or when it cannot run (the
simulator), the same reading runs with code rules in its place. They fill only what is
unambiguous:

| Field | Rule |
|---|---|
| Amount | the money value on the same row as *Nominal, Jumlah, Total, Total Bayar, Amount* — only if exactly one such row |
| Fee | the money value on a row with *Biaya, Admin, Fee* — only if exactly one |
| Date | the only date on the receipt |
| Account | the only bank on the receipt |
| Note | the text after *Tujuan, Penerima, Nama Penerima, Ke, Beneficiary* on the same or the next row |
| Category | not filled |

The owner is not told which path read the receipt.

### 4.10 Receipt reading in Manage `[→ AG8, AG9]`

A **Receipt reading** row in Manage, below Accounts, with a scan-text glyph on the amber
wash, subtitle by state. Its screen opens with a card saying what it does ("Fill expenses
from receipts … Nothing leaves the phone."), then a **MODEL** card, then a footnote that
receipts are read with simpler rules until the model is here:

| State | Subtitle | Screen shows |
|---|---|---|
| Not downloaded | Model not downloaded | what it does, "Gemma 4 E2B · 3.6 GB", **Download model** |
| Downloading | 41% · 1.5 of 3.6 GB | progress, **Pause**; a broken download resumes from where it stopped |
| Paused / failed | Paused at 41% | **Resume**, and the error if one |
| Ready | Gemma 4 E2B · on this iPhone | **Remove model** (confirmation: "Receipts will be read with simpler rules") |

- On a cellular connection, Download first asks **"Download 3.6 GB over cellular?"**
  (Download / Cancel). On Wi-Fi it starts at once.
- The model comes from Hugging Face (`mlx-community/gemma-4-e2b-it-4bit`) and is kept in
  Application Support, excluded from backup.
- The model is loaded into memory on the first reading and released when the app goes to
  the background.

---

## 5. Lifetime

| Thing | Lives for |
|---|---|
| A waiting receipt | until saved or discarded; this device only |
| The "Receipt N of M" run | until the inbox is empty, or Later |
| Needs review + receipt image | until checked (§4.7); synced |
| The downloaded model | until removed in Manage, or the app is deleted |
| The loaded model | until the app goes to the background |

## 6. Unaffected

- The expense form's layout, chips, keypad, Save rule and discard question (outside the
  inbox run).
- **Auto items' Needs review**: still reviewed in the Plan lens's sheet, not counted in
  §4.2's banner, not tagged Check.
- Totals, Insights, the plan, the expense filter: a receipt expense is an ordinary
  expense.
- The store's location and CloudKit container.

---

## 7. Decision log

Settled in a grilling session on 2026-11-08.

| # | Decision | Drawn in |
|---|---|---|
| 1 | Shared receipts wait in a **per-device inbox**; the share sheet only stores them — not a form in the share sheet, not an unofficial jump into the app | `AG1`, `AG2` |
| 2 | MLX Swift (mlx-swift-lm, swift-huggingface, swift-transformers) joins ExpenseKu; the model is **downloaded and removed from Manage** — *owner override*, against a download offered on first use | `AG8`, `AG9` |
| 3 | Without the model, **code rules** fill what is unambiguous | `AG4` |
| 4 | In-app sources: Photos, Camera, Paste | `AG3` |
| 5 | **Read receipt** lives in the expense form's toolbar | `AG3` |
| 6 | The form is filled **silently** — *owner override*, against a receipt card on the form | `AG4` |
| 7 | A fee is **added to the amount** as `amount+fee` | `AG4` |
| 8 | Transfers to the owner's own accounts are **treated like any other** — *owner override*, against asking | — an absence |
| 9 | The counterparty goes to the **note** and tags a matching existing Person; never creates one | `AG4` |
| 10 | Account by bank logo; several → most used; none → **None** | `AG4` |
| 11 | Category is **picked by Gemma** — *owner override*, against reusing the last Category for the same note | `AG4` |
| 12 | A receipt expense is saved **Needs review** | `AG2` |
| 13 | Review shows as a **Check tag plus a banner** — *owner override*, against the tag alone | `AG2`, `AG7` |
| 14 | The receipt image is kept **until checked**, then deleted (schema V8) | `AG7` |
| 15 | Several waiting receipts are worked **one after another**, oldest first; Cancel → Discard receipt / Later | `AG4`, `AG5` |
| 16 | Both banners in **every lens**, inbox first, counts ignore filters | `AG2` |
| 17 | **Gemma 4 E2B only** | `AG9` |
| 18 | Cellular download **asks first**; downloads resume | `AG9` |
| 19 | Words on screen in **English** | all |
| 20 | Reading fills **only empty or default fields** | `AG4` |
| 21 | Identical images never enter the inbox twice; same amount + same day → **Looks already logged** | `AG6` |
| 22 | The review sheet shows **receipt and expense side by side**, Edit / Looks right | `AG7` |

Design calls made while drawing flow AG, approved at the design gate the same day:

| # | Call | Drawn in |
|---|---|---|
| 23 | Both banners share one card, inbox icon amber, review icon neutral, each with a caption | `AG2` |
| 24 | Check tag = accent capsule after the Category name | `AG2` |
| 25 | Read receipt = round glass button at the nav bar's trailing edge; Photos, Camera, Paste | `AG3` |
| 26 | "Receipt 1 of 3" is the navigation subtitle | `AG4` |
| 27 | The run's Cancel dialog adds **Keep editing** | `AG5` |
| 28 | Reading = centred card with spinner over the dimmed form | `AG3b` |
| 29 | Review sheet: accent Looks right, `surface` Edit, ✕ to close | `AG7` |
| 30 | Manage row glyph: scan text on the amber wash | `AG8` |
| 31 | Receipt reading screen: explainer card, MODEL card with progress, rules footnote | `AG9` |
| 32 | Share extension: dark sheet, thumbnail, "Saved to ExpenseKu", accent Done | `AG1` |

Defaults chosen without asking, confirmed at the gate: receipt date fills the date (none →
Now); Me stays; Envelope untouched; the Person match rule in §4.4; the note as printed;
"Reading receipt…" while reading; the model loaded on first use and released in the
background; images and PDFs accepted; Check tag and banner only for receipt expenses;
reading on Edit also marks Needs review; its own PRD plus ADR-0014; built on
`feature/receipt-reading` and **not merged to `main` until the owner says so**.

---

## 8. Design traceability

Flow AG on page `05 · Proposals — not built`. Sample data in every frame: Sat 8 Nov
2026, 15.10 now; the BCA receipt "Rp 60.000 + biaya Rp 2.500, 22 Aug 14.28, to MUHAMMAD
FADHIL"; three receipts waiting; three receipt expenses to check.

| Frame | Covers |
|---|---|
| **AG1** · Share sheet — Saved | §4.1 |
| **AG2** · Expenses with both banners and a Check row | §4.2, §4.7 tag |
| **AG3** · Read receipt menu · **AG3b** · Reading receipt… | §4.3 |
| **AG4** · Form filled from the BCA receipt, "Receipt 1 of 3" · **AG4b** · the same, scrolled to Account and note | §4.4, §4.5, §4.9 |
| **AG5** · Cancel during the run | §4.5 |
| **AG6** · Looks already logged | §4.6 |
| **AG7** · To check sheet | §4.7, §4.8 |
| **AG8** · Manage with Receipt reading | §4.10 row |
| **AG9** · Receipt reading, downloading · **AG9a** not downloaded · **AG9c** ready · **AG9d** cellular confirmation | §4.10 states |

### 8.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| A reading the owner cannot see is filled silently, so a wrong value would land unseen | `ReceiptSanity` drops an amount under Rp 1.000 (the owner's "Rp 300 transfer") and a fee that is zero or not below the amount, on both the model and the rules path | `ReceiptSanity` |
| Rules: a label whose value is on the next row (Superbank's "Jumlah Transfer" over "Rp 100.000") | A label row with no value of its own reads the row under it | `ReceiptRules` |
| Rules: "Nominal" and "Total" both labelled, with different values | Not sure, so no amount | `ReceiptRules` |
| A receipt that names no bank (a shop receipt paid in cash) | Keeps the form's default Account; None only when a bank is named and no Account wears its logo | `ReceiptFill` |
| §4.6 "before the form opens" for the inbox | The form opens under the "Reading receipt…" card, and the alert appears before anything is filled | `ExpenseEditorView.read` |
| A system Cancel appeared as a third button on Looks already logged | Log anyway / Fill anyway carries the cancel role | `ExpenseEditorView` |
| iOS 26 draws the run's confirmation dialog as a popover | Keep editing is its cancel: a tap outside it | `ExpenseEditorView` |
| Thumbnails of wide receipts lost their labels | Cropped to the top-leading corner | `ReceiptThumbnail` |
| A paused download showed 0 %, and a half download could not be removed | Paused keeps the bytes of the file in flight; Paused offers Remove download | `ReceiptModelStore`, `ReceiptModelCard` |
| Resume after a relaunch | Finished files are kept; the file in flight restarts, because URLSession's resume data lives in memory | `ReceiptModelStore` |
| MLXHuggingFace needs macro packages and a hub client the app does not use | A hand-written tokenizer bridge and a refusing `Downloader` load the model from its folder; the app links MLXLLM, MLXLMCommon and Tokenizers only | `GemmaTokenizerBridge`, `LocalModelDownloader` |
| Where the receipt image is stored | JPEG, at most 1600 pt on its long side, a PDF as its first page | `ReceiptImageData` |
| The share extension and the app share the inbox code | `ReceiptInboxFolder`, `ReceiptInboxItem` and `Theme` are members of both targets | `project.pbxproj` |
| Driving the flow in the simulator | `-seedReceipts` adds a BCA Account, two receipts drawn with SwiftUI in the inbox, and one Belanja expense to check | `DebugReceiptSeed` |
| Before TestFlight | Deploy the V8 field (`receiptImage`) to CloudKit Production; register the App Group through automatic signing on a device build | — |

