//
//  ReceiptRules.swift
//  ExpenseKu
//
//  The reading without the model (docs/prd/receipt-reading.md §4.9): before Gemma is
//  downloaded, after it is removed, and in the simulator. It fills only what is
//  unambiguous and never a Category.
//

import Foundation

nonisolated enum ReceiptRules {
    static let amountLabels = ["nominal", "jumlah", "total", "total bayar", "amount", "jumlah transfer"]
    static let feeLabels = ["biaya", "admin", "fee", "biaya admin", "biaya transfer"]
    static let counterpartyLabels = ["tujuan", "penerima", "nama penerima", "ke", "beneficiary",
                                     "beneficiary name", "rekening tujuan"]

    static func read(_ receipt: ReceiptText, candidates: ReceiptCandidates) -> ReceiptReading {
        var reading = ReceiptReading()
        reading.amount = onlyValue(labelled: amountLabels, in: receipt, candidates: candidates)
        reading.fee = onlyValue(labelled: feeLabels, in: receipt, candidates: candidates)
        let dates = Set(candidates.dates.map(\.value))
        reading.date = dates.count == 1 ? dates.first : nil
        let banks = Set(candidates.banks.map(\.brandID))
        reading.bankBrandID = banks.count == 1 ? banks.first : nil
        reading.counterparty = counterparty(in: receipt, candidates: candidates)
        return ReceiptSanity.checked(reading)
    }

    /// The one value on the rows carrying a label, or on the row under a label row that
    /// carries no value of its own. Two different values mean the rule is not sure.
    private static func onlyValue(labelled labels: [String], in receipt: ReceiptText,
                                  candidates: ReceiptCandidates) -> Decimal? {
        var values: Set<Decimal> = []
        for (index, row) in receipt.rows.enumerated() where rowHasLabel(row, labels) {
            var found = money(in: row, candidates)
            if found.isEmpty, index + 1 < receipt.rows.count {
                found = money(in: receipt.rows[index + 1], candidates)
            }
            values.formUnion(found)
        }
        return values.count == 1 ? values.first : nil
    }

    private static func money(in row: [TextSpan], _ candidates: ReceiptCandidates) -> [Decimal] {
        let ids = Set(row.map(\.id))
        return candidates.money.filter { ids.contains($0.spanID) }.map(\.value)
    }

    private static func rowHasLabel(_ row: [TextSpan], _ labels: [String]) -> Bool {
        row.contains { span in
            let words = words(of: span.text)
            return labels.contains { label in
                let labelWords = label.split(separator: " ").map(String.init)
                return words.count >= labelWords.count && Array(words.prefix(labelWords.count)) == labelWords
            }
        }
    }

    private static func words(of text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    private static func isLabel(_ text: String, _ labels: [String]) -> Bool {
        labels.contains(words(of: text).joined(separator: " "))
    }

    private static func counterparty(in receipt: ReceiptText, candidates: ReceiptCandidates) -> String? {
        let moneySpans = Set(candidates.money.map(\.spanID))
        let bankSpans = Set(candidates.banks.map(\.spanID))
        func usable(_ span: TextSpan) -> String? {
            guard !moneySpans.contains(span.id), !bankSpans.contains(span.id),
                  !isLabel(span.text, counterpartyLabels) else { return nil }
            let text = span.text.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
            return text.contains(where: \.isLetter) ? text : nil
        }

        var found: Set<String> = []
        for (index, row) in receipt.rows.enumerated() {
            for (position, span) in row.enumerated() {
                if let colon = span.text.firstIndex(of: ":"),
                   isLabel(String(span.text[..<colon]), counterpartyLabels) {
                    let rest = span.text[span.text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    if rest.contains(where: \.isLetter) { found.insert(rest) }
                    continue
                }
                guard isLabel(span.text, counterpartyLabels) else { continue }
                if position + 1 < row.count, let name = usable(row[position + 1]) {
                    found.insert(name)
                } else if index + 1 < receipt.rows.count, let first = receipt.rows[index + 1].first,
                          let name = usable(first) {
                    found.insert(name)
                }
            }
        }
        return found.count == 1 ? found.first : nil
    }
}
