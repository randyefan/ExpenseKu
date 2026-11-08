//
//  ReceiptRun.swift
//  ExpenseKu
//
//  The inbox worked one receipt after another, oldest first: which one is open and how
//  many the run holds (docs/prd/receipt-reading.md §4.5).
//

import Foundation

struct ReceiptRun: Identifiable, Hashable {
    enum Outcome {
        case saved
        case discarded
        case later
    }

    let item: ReceiptInboxItem
    let position: Int
    let total: Int

    var id: String { item.id }

    var subtitle: String { "Receipt \(position) of \(total)" }

    static func start(with items: [ReceiptInboxItem]) -> ReceiptRun? {
        items.first.map { ReceiptRun(item: $0, position: 1, total: items.count) }
    }

    /// The next receipt after this one left the inbox, or nil when the run is over.
    func next(in items: [ReceiptInboxItem]) -> ReceiptRun? {
        guard let item = items.first(where: { $0 != self.item }) else { return nil }
        return ReceiptRun(item: item, position: position + 1, total: max(total, position + items.count))
    }
}
