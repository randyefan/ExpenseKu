//
//  CandidateExtractor.swift
//  ExpenseKu
//
//  Lists every money value, date and bank on a receipt. Code finds the values; the model
//  only ever chooses among them, so it cannot invent a number (ADR-0014).
//
//  Money: an Rp/IDR-prefixed number, or any thousand-grouped one, in either the
//  Indonesian (100.000,00) or English (60,000.00) style. Dates: Indonesian and English
//  month names, or dd/mm/yyyy, each with an optional time.
//

import Foundation

nonisolated enum CandidateExtractor {
    static func extract(from receipt: ReceiptText) -> ReceiptCandidates {
        var money: [MoneyCandidate] = []
        var dates: [DateCandidate] = []
        var banks: [BankCandidate] = []
        for span in receipt.spans {
            for value in amounts(in: span.text) {
                money.append(MoneyCandidate(id: "M\(money.count + 1)", value: value, spanID: span.id))
            }
            if let value = date(in: span.text) {
                dates.append(DateCandidate(id: "D\(dates.count + 1)", value: value, spanID: span.id))
            }
            for brandID in bankBrands(in: span.text) {
                banks.append(BankCandidate(id: "B\(banks.count + 1)", brandID: brandID, spanID: span.id))
            }
        }
        return ReceiptCandidates(money: money, dates: dates, banks: banks)
    }

    static func amounts(in text: String) -> [Decimal] {
        text.matches(of: /\d[\d.,]*\d|\d/).compactMap { match in
            let token = String(match.output)
            let before = text[..<match.range.lowerBound].trimmingCharacters(in: .whitespaces)
            let prefix = before.uppercased()
            let hasCurrency = prefix.hasSuffix("RP") || prefix.hasSuffix("IDR")
            let isGrouped = token.wholeMatch(of: /\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?/) != nil
            let isPlainWithCurrency = hasCurrency && token.wholeMatch(of: /\d+(?:[.,]\d{2})?/) != nil
            guard isGrouped || isPlainWithCurrency, let value = parseAmount(token) else { return nil }
            let isNegative = before.hasSuffix("-") || prefix.hasSuffix("-RP") || prefix.hasSuffix("-IDR")
            return isNegative ? -value : value
        }
    }

    /// A last separator followed by exactly two digits is the decimal point.
    static func parseAmount(_ token: String) -> Decimal? {
        guard let last = token.lastIndex(where: { $0 == "." || $0 == "," }) else {
            return Decimal(string: token)
        }
        let fraction = token[token.index(after: last)...]
        if fraction.count == 2, fraction.allSatisfy(\.isNumber) {
            let whole = token[..<last].filter(\.isNumber)
            return Decimal(string: "\(whole).\(fraction)")
        }
        let digits = token.filter(\.isNumber)
        return digits.isEmpty ? nil : Decimal(string: digits)
    }

    private static let monthPrefixes: [String: Int] = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "mei": 5, "may": 5, "jun": 6, "jul": 7,
        "agu": 8, "agt": 8, "aug": 8, "sep": 9, "okt": 10, "oct": 10, "nov": 11, "des": 12, "dec": 12,
    ]

    static func date(in text: String) -> LocalDateTime? {
        let time = text.firstMatch(of: /(\d{1,2})[:.](\d{2})(?::\d{2})?(?!\d)/).flatMap { match -> (Int, Int)? in
            guard let hour = Int(match.1), let minute = Int(match.2), hour < 24, minute < 60 else { return nil }
            return (hour, minute)
        }
        if let match = text.firstMatch(of: /(\d{1,2})\s+([A-Za-z]{3,})\.?\s+(\d{4})/),
           let day = Int(match.1), let year = Int(match.3),
           let month = monthPrefixes[String(match.2.prefix(3)).lowercased()] {
            return LocalDateTime(year: year, month: month, day: day, hour: time?.0, minute: time?.1)
        }
        if let match = text.firstMatch(of: /(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})/),
           let day = Int(match.1), let month = Int(match.2), var year = Int(match.3), (1...12).contains(month) {
            if year < 100 { year += 2000 }
            return LocalDateTime(year: year, month: month, day: day, hour: time?.0, minute: time?.1)
        }
        return nil
    }

    private static let upperCaseBanks: [(brandID: String, word: String)] = [
        ("bca", "BCA"), ("bri", "BRI"), ("bni", "BNI"), ("bsi", "BSI"), ("dana", "DANA"),
    ]

    private static let namedBanks: [(brandID: String, phrase: String)] = [
        ("bca", "bank central asia"), ("bri", "bank rakyat"), ("bni", "bank negara"),
        ("mandiri", "mandiri"), ("jago", "jago"), ("seabank", "seabank"), ("cimb-niaga", "cimb"),
        ("danamon", "danamon"), ("superbank", "superbank"),
    ]

    /// Short bank names count only in capitals ("BCA", never "bca" inside a word); longer
    /// names count in any case, as whole words.
    static func bankBrands(in text: String) -> [String] {
        let words = Set(text.split(whereSeparator: { !$0.isLetter }).map(String.init))
        let lowerWords = text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
        let joined = " " + lowerWords.joined(separator: " ") + " "
        var found: [String] = []
        for bank in upperCaseBanks where words.contains(bank.word) && !found.contains(bank.brandID) {
            found.append(bank.brandID)
        }
        for bank in namedBanks where !found.contains(bank.brandID) && joined.contains(" \(bank.phrase) ") {
            found.append(bank.brandID)
        }
        return found
    }
}
