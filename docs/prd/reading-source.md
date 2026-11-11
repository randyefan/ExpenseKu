# PRD — Who read the receipt

Status: Built
Date: 2026-11-09 · grilled, drawn (flow AI), approved and built the same day, on `feature/reading-source`
Owner: Randy Efan

Companion documents: `docs/prd/receipt-reading.md` (the reading this labels; this PRD amends its
§4.4 and §4.9), `CONTEXT.md`, ADR-0014, and the **Wonder file "ExpenseKu"** (org `randy-efan`),
page `05 · Proposals — not built`, **Flow AI**. Frame references appear inline as `[→ AI2]`.

---

## 1. What this is

A receipt is read one of two ways (receipt-reading.md §1, §4.9): **Gemma**, an AI model on the
iPhone, picks the values; or, without it, **OCR** (Vision's text recognition) and code rules fill
only what they are sure of. Today the owner is never told which, so a form with no Category and
a form Gemma filled look the same, and nothing says the model is missing.

This feature says it: a card at the top of the form after a reading, and a tag on each card of
the To check sheet. The words make plain that **OCR is not AI** and **Gemma is an AI model**.

## 2. Goals

1. After a reading the owner knows, before saving, whether AI read the receipt.
2. When OCR read it because the model is missing, the owner can reach the download in one tap.
3. Later, on the To check sheet, each receipt expense still says who read it.

## 3. Non-goals

- Marking which **fields** came from the reading. The card speaks for the whole reading.
- A source on the expense **row** or its Check tag. Only the form and the To check sheet.
- Changing how a receipt is read. The reader, rules and model are untouched.
- Closing the card. It stays while the form is open.

---

## 4. The rules

### 4.1 The reading's source

A reading has one of three sources, decided where it is made (`ReceiptReader`):

| Source | When | Saved as |
|---|---|---|
| **Gemma** | the model was asked and its grounded answer filled at least one field | `gemma` |
| **OCR, no model** | there was no model to ask: not downloaded, removed, or it cannot run (the simulator) | `ocrNoModel` |
| **OCR, Gemma couldn't read it** | the model was asked, answered nothing usable, and the rules filled the form | `ocrModelFailed` |

- A reading that filled **nothing** has no source shown: the form opens empty, as today.
- A reading kept beside its receipt before this feature (§4.11 of receipt-reading.md) carries
  no source, and shows none.
- A rules reading read again once the model is ready (receipt-reading.md §4.11) takes the new
  reading's source.

### 4.2 The card on the form `[→ AI2]`

After a reading fills the form, a card sits between the navigation bar and the amount. It is
shaped like a receipt banner row: an icon circle, a title, a caption.

| Source | Icon | Title | Caption |
|---|---|---|---|
| Gemma | `sparkles`, accent on the accent wash | **Read by Gemma AI** | Gemma is an AI model running on this iPhone. It picked these values from the receipt — check them before you save. |
| OCR, no model | `text.viewfinder`, text on `surface` | **Read by OCR, no AI** | OCR only recognises text — it isn't AI, so Category is left for you. Download Gemma, the AI model, in Receipt reading. |
| OCR, Gemma couldn't read it | `text.viewfinder`, text on `surface` | **Read by OCR, no AI** | Gemma, the AI model, couldn't read this receipt. OCR (text recognition, not AI) filled only what it was sure of. |

- **OCR, no model** carries a chevron, and tapping the card opens **Receipt reading**
  (receipt-reading.md §4.10) inside the form, back to the form with ‹. The other two cards
  take no tap.
- While the model is **ready**, the no-model card drops its last sentence and its chevron
  ("…so Category is left for you.") — the reading still came from OCR, but there is nothing
  left to download.
- The card stays until the form closes. Changing a value does not change or remove it.
- It is hidden while "Reading receipt…" shows, and replaced when another reading fills the form.
- **On Edit** of an expense still to check, the card shows the source saved with it (§4.3).
  An expense with no saved source, or already checked, shows no card.

### 4.3 Saving the source `[→ AI5]`

- An expense saved from a receipt keeps the reading's source beside its receipt image
  (`Expense.receiptSourceValue`, a `ReceiptReadingSource` raw value read through
  `Expense.receiptSource`; schema **V9**).
- The source clears with the image, by any of the ways that check an expense
  (receipt-reading.md §4.7).
- A receipt expense saved before V9 has no source.

### 4.4 The To check sheet `[→ AI5]`

Each card gets a small capsule under its date:

| Saved source | Tag |
|---|---|
| `gemma` | `sparkles` + **Gemma AI**, accent text on the accent wash |
| `ocrNoModel`, `ocrModelFailed` | `text.viewfinder` + **OCR, no AI**, text on `surface` |
| none | no tag |

---

## 5. Lifetime

| Thing | Lives for |
|---|---|
| The card on the form | the form, from the reading that filled it until it closes |
| A waiting receipt's source | its reading file beside it in the inbox (receipt-reading.md §4.11) |
| A saved expense's source | until the expense is checked or deleted |

## 6. Unaffected

The reader, the rules and the model; what a reading fills (receipt-reading.md §4.4); Looks
already logged; the inbox run and its banners; the Check tag on rows; Manage.

## 7. Decision log

Settled in a grilling session on 2026-11-09.

| # | Decision | Drawn in |
|---|---|---|
| 1 | The source shows on the form **and** on the To check sheet, so it is saved on the expense (schema V9) — *owner override*, against the form only | `AI2`, `AI5` |
| 2 | Three sources on the form: Gemma, OCR because there is no model (with a way to get it), OCR because Gemma couldn't read it; two on the sheet | `AI2` |
| 3 | A **notice card** above the amount (option B) — *owner override*, against a chip under the title (A) | `AI2` |
| 4 | The words say plainly that OCR is not AI and Gemma is an AI model; Gemma's glyph is **sparkles** — owner's revision at the design gate | `AI2`, `AI5` |

Options drawn and not chosen: A chip under the title `[AI1]`, C caption under the amount
`[AI3]`, D pill over the keypad that fades `[AI4]`.

Defaults chosen without asking, confirmed at the gate: the card stays while the form is open,
cannot be closed and does not follow edits; no card for an empty reading; only the no-model card
is tappable, and it opens Receipt reading inside the form; a model that answered nothing counts
as "Gemma couldn't read it"; a rules reading redone by the model takes the new source; Edit of
an expense to check shows its saved source; the source clears with the image; V8 receipt
expenses get no tag; `text.viewfinder` for OCR and `sparkles` for Gemma; the sheet's tag under
the date; words in English; its own PRD amending receipt-reading.md §4.9 ("The owner is not told
which path read the receipt") and, in part, decision 6 (the form filled silently).

---

## 8. Design traceability

Flow AI on page `05 · Proposals — not built`. Sample data as flow AG: Sat 8 Nov 2026, 15.10 now;
the BCA receipt "Rp 60.000 + biaya Rp 2.500, 22 Aug 14.28, to MUHAMMAD FADHIL", read without the
model, so Category is required; three receipt expenses to check.

| Frame | Covers |
|---|---|
| **AI2** · Form with the OCR, no model card · **AI2 states** · the three cards | §4.1, §4.2 |
| **AI5** · To check sheet, two Gemma AI tags and one OCR, no AI | §4.3, §4.4 |
| AI1, AI3, AI4 · options not chosen | — |

### 8.1 Closed during implementation

| Gap | Answer | Where |
|---|---|---|
| At the accessibility text sizes the no-model caption alone filled the screen and pushed the amount under the keypad | The card's Dynamic Type is capped at XXXL | `ReceiptSourceCard` |
| A reading from Photos, Camera or Paste came back without knowing who read it | The form's own reads return the same kept shape as the inbox's, source included | `ReceiptReadAhead.read` |
| "Looks already logged" held only the reading, so Fill anyway lost the source | The look-alike carries the source too | `ReceiptLookAlike` |
| MLX cannot run in the simulator, so no Gemma reading can be made there | `-seedReceipts` saves its receipt expense still to check as read by Gemma; the sheet tag and the Edit card show it. The reader's three outcomes are tested with literal model answers | `DebugReceiptSeed`, `ReceiptReadingSourceTests` |
| Unreachable in the simulator: "Gemma couldn't read it", and the no-model card once the model is ready | Unit tests | `ReceiptReadingSourceTests` |
