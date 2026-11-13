# ADR-0014 — Receipts are read on the device, and their photos are kept only until checked

Status: Accepted
Date: 2026-11-08
Relates to: ADR-0007 (Auto items and Needs review), ADR-0012 (bank-logo catalog)

## Context

The owner wants the expense form filled from a receipt: a transfer receipt shared from a
banking app, or a photo of a paper one. `CONTEXT.md` lists "receipt photos" as out of
scope, and the app has no server: the owner's data lives only in their private CloudKit
database.

A spike (`.scratch/receipt-ai/`, 8 Nov 2026) compared ways to read a receipt:

1. **A cloud model.** The most accurate, and it sends names and account numbers to a
   third party. Rejected: the app has no backend and keeps none of the owner's data
   anywhere else.
2. **Apple Foundation Models.** On-device, but it does not support Indonesian (checked on
   macOS 27.2).
3. **OCR and code rules only.** Works for one bank's layout at a time, and breaks on the
   next one.
4. **OCR, code-listed candidates, and a small on-device LLM that picks among them.**
   Gemma 4 E2B (4-bit, MLX) scored 27–28 of 28 fields on four receipts, in 1–3 s with
   3.5 GB peak memory on an M3 Pro. The model only returns ids of listed values, so it
   cannot write a number that is not on the receipt.

Sharing from another app adds a second question. A share extension may use about 120 MB
and cannot open its containing app by any supported API.

## Decision

**Read with 4, on the iPhone, and fall back to 3 when the model is absent.**

- Vision OCR, candidate listing, and validation are app code. Gemma 4 E2B is downloaded
  on request from Manage (3.6 GB, Hugging Face) and runs through MLX Swift. This adds
  three packages to ExpenseKu: `mlx-swift-lm`, `swift-huggingface`, and
  `swift-transformers`. The model download is the app's only network call outside
  CloudKit.
- The share extension only stores the shared file in an App Group folder (the **receipt
  inbox**). Reading happens in the app. The SwiftData store does not move.
- An expense saved from a receipt is **Needs review** and carries the receipt image
  (`Expense.receiptImage`, external storage, schema V8, additive) until the owner checks
  it. Checking clears both, and the image is deleted.

## Consequences

- "Receipt photos" leaves the out-of-scope list in a narrow form: a photo exists only
  while its expense waits for review. There is no gallery, and an expense keeps no
  photo once checked.
- Needs review gains a second source. Auto items keep their own review in the Plan lens.
  Receipt expenses are told apart by carrying `receiptImage`, not by having no
  `planItem`: an Auto expense whose item was deleted keeps its flag and has no item
  either (corrected 9 Nov 2026, after the first device run showed one as a receipt).
- MLX cannot run in the iOS Simulator, so simulator checks cover the rules path and the
  UI. The model's accuracy is measured on the Mac with the same ReceiptKit code.
- The app needs `com.apple.developer.kernel.increased-memory-limit` and an App Group
  entitlement.
- CloudKit Production needs the V8 field deployed before a TestFlight build carries it.

## Amendment — 14 Nov 2026: receipt descriptions

The owner approved image-assisted analysis that chooses an existing Category and writes a
short Indonesian expense description. Amount, fee, date, bank and counterparty remain
candidate-grounded. The description is a bounded free-text suggestion from visible receipt
evidence, saved in the existing Expense Note only while that field is empty and untouched;
there is no SwiftData schema change. The prompt prohibits guessing a transfer's purpose.
The owner can clear or edit the suggestion before saving. Stored inbox analyses carry a
version so older results are refreshed once for this prompt when Gemma is available.
