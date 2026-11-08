//
//  ReceiptInbox.swift
//  ExpenseKu
//
//  The inbox as the app sees it: the waiting receipts, oldest first, re-read whenever the
//  app comes to the foreground, since the share extension writes while it is away.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReceiptInbox {
    private let folder: ReceiptInboxFolder
    private(set) var items: [ReceiptInboxItem] = []

    init(folder: ReceiptInboxFolder = .shared) {
        self.folder = folder
        refresh()
    }

    func refresh() {
        items = folder.items()
    }

    func add(_ data: Data, fileExtension: String) {
        _ = try? folder.add(data, fileExtension: fileExtension)
        refresh()
    }

    func remove(_ item: ReceiptInboxItem) {
        folder.removeReading(for: item)
        folder.remove(item)
        refresh()
    }
}
