//
//  ReceiptInboxFolder+Readings.swift
//  ExpenseKu
//
//  Readings kept beside their receipts (docs/prd/receipt-reading.md §4.11), as hidden
//  files so `items()` and the share extension never take one for a receipt. App only:
//  the share extension does not read.
//

import Foundation

nonisolated extension ReceiptInboxFolder {
    func storedReading(for item: ReceiptInboxItem) -> StoredReceiptReading? {
        guard let data = try? Data(contentsOf: readingURL(for: item)) else { return nil }
        return try? JSONDecoder().decode(StoredReceiptReading.self, from: data)
    }

    func store(_ reading: StoredReceiptReading, for item: ReceiptInboxItem) {
        guard let data = try? JSONEncoder().encode(reading) else { return }
        try? data.write(to: readingURL(for: item), options: .atomic)
    }

    func removeReading(for item: ReceiptInboxItem) {
        try? FileManager.default.removeItem(at: readingURL(for: item))
    }

    private func readingURL(for item: ReceiptInboxItem) -> URL {
        url.appending(path: ".\(item.id).reading.json")
    }
}
