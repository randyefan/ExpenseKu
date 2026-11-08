//
//  ReceiptText.swift
//  ExpenseKu
//
//  A receipt's text as rows, top to bottom, each row's spans left to right. Rows are
//  what the rules read "on the same row as" from (docs/prd/receipt-reading.md §4.9).
//

import Foundation

nonisolated struct ReceiptText: Codable, Sendable, Hashable {
    let rows: [[TextSpan]]

    var spans: [TextSpan] { rows.flatMap(\.self) }

    func span(_ id: String) -> TextSpan? { spans.first { $0.id == id } }

    /// Builds rows from plain lines, numbering spans S1, S2… in reading order. Lines are
    /// split into spans on runs of two or more spaces.
    static func lines(_ lines: [String]) -> ReceiptText {
        var next = 1
        let rows = lines.map { line in
            line.split(separator: /\s{2,}/).map { piece in
                defer { next += 1 }
                return TextSpan(id: "S\(next)", text: String(piece))
            }
        }
        return ReceiptText(rows: rows.filter { !$0.isEmpty })
    }
}
