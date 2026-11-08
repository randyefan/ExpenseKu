//
//  ReceiptResolver.swift
//  ExpenseKu
//
//  Turns Gemma's JSON answer into a grounded reading. An answer counts only when it
//  names a listed candidate: by its id, by the id of the text it came from, or by a value
//  equal to one (the model answers all three ways). Anything else is dropped, never
//  filled (ADR-0014).
//

import Foundation

nonisolated enum ReceiptResolver {
    static func resolve(answer output: String, receipt: ReceiptText, candidates: ReceiptCandidates,
                        categories: [String]) -> ReceiptReading {
        guard let answer = answerObject(in: output) else { return ReceiptReading() }

        var reading = ReceiptReading()
        reading.amount = pick(answer["amount"], from: candidates.money) {
            CandidateExtractor.parseAmount($0) == $1.value
        }?.value
        reading.fee = pick(answer["fee"], from: candidates.money) {
            CandidateExtractor.parseAmount($0) == $1.value
        }?.value
        reading.date = pick(answer["date"], from: candidates.dates) {
            $0.hasPrefix($1.value.description) || $1.value.description.hasPrefix($0)
        }?.value
        reading.bankBrandID = pick(answer["payer_bank"], from: candidates.banks) {
            $0.lowercased() == $1.brandID
        }?.brandID
        if let answered = answer["counterparty"], answered.lowercased() != "null" {
            reading.counterparty = (receipt.span(answered)
                ?? receipt.spans.first { $0.text.localizedCaseInsensitiveCompare(answered) == .orderedSame })?.text
        }
        if let answered = answer["category"] {
            reading.categoryName = categories.first { $0.localizedCaseInsensitiveCompare(answered) == .orderedSame }
        }
        return ReceiptSanity.checked(reading)
    }

    static func answerObject(in output: String) -> [String: String]? {
        guard let start = output.firstIndex(of: "{"), let end = output.lastIndex(of: "}"), start < end,
              let object = try? JSONSerialization.jsonObject(with: Data(output[start...end].utf8)) as? [String: Any]
        else { return nil }
        return object.compactMapValues { value in
            switch value {
            case let string as String: string
            case let number as NSNumber: number.stringValue
            default: nil
            }
        }
    }

    private static func pick<C: IdentifiedCandidate>(
        _ answered: String?, from candidates: [C], matchesValue: (String, C) -> Bool
    ) -> C? {
        guard let answered, answered.lowercased() != "null" else { return nil }
        return candidates.first { $0.id == answered }
            ?? candidates.first { $0.spanID == answered }
            ?? candidates.first { matchesValue(answered, $0) }
    }
}
