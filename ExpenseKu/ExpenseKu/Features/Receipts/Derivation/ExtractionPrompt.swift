//
//  ExtractionPrompt.swift
//  ExpenseKu
//
//  The prompt Gemma answers. It lists the receipt's text with ids, the candidates code
//  found, and the owner's Category names, and asks for ids only (ADR-0014). The wording
//  is the spike's prompt v2, which scored 27–28 of 28 fields on the Mac.
//

import Foundation

nonisolated enum ExtractionPrompt {
    static func make(receipt: ReceiptText, candidates: ReceiptCandidates, categories: [String]) -> String {
        let lines = receipt.rows.map { row in
            row.map { "[\($0.id)] \($0.text)" }.joined(separator: " | ")
        }
        let money = candidates.money.map { "\($0.id) = \($0.value) (in \($0.spanID))" }
        let dates = candidates.dates.map { "\($0.id) = \($0.value) (in \($0.spanID))" }
        let banks = candidates.banks.map { "\($0.id) = \($0.brandID) (in \($0.spanID))" }

        return """
        You read Indonesian payment receipts: bank transfer proofs, e-wallet payments and shop receipts.
        Below is the OCR text of one receipt. Each piece of text has an id in brackets. \
        Pieces on the same line are separated by |. Ignore advertising and watermark text.

        RECEIPT
        \(lines.joined(separator: "\n"))

        MONEY CANDIDATES
        \(money.isEmpty ? "none" : money.joined(separator: "\n"))

        DATE CANDIDATES
        \(dates.isEmpty ? "none" : dates.joined(separator: "\n"))

        BANK CANDIDATES
        \(banks.isEmpty ? "none" : banks.joined(separator: "\n"))

        CATEGORIES
        \(categories.isEmpty ? "none" : categories.joined(separator: "\n"))

        Answer with one JSON object and nothing else, using only ids and names listed above:
        {"amount": money id of the final total paid or sent, after discounts and not including fees. \
        Not a single item's price, not cash handed over (TUNAI, CASH) and not change (KEMBALI),
         "fee": money id of a separate admin or transfer fee (Biaya Admin, Fee), or null. A discount (DISKON) is not a fee,
         "date": date id of when the transaction happened, or null,
         "payer_bank": bank id of the bank or wallet the money left from, or null if paid in cash,
         "counterparty": text id holding only the name of the person who received the money \
        (usually right after a label such as Tujuan, Penerima, Rekening Tujuan or Beneficiary Name) \
        or the name of the shop. Never a label, bank name, slogan or watermark. Or null,
         "category": the one category name above that best fits what was paid for, or null}
        """
    }
}
