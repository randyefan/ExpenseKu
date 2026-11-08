//
//  ReceiptInboxItem.swift
//  ExpenseKu
//
//  One receipt waiting in the inbox: a file in the shared folder, named
//  `<seconds since 1970>-<sha256>.<ext>` so its order and its identity are in the name.
//

import Foundation

nonisolated struct ReceiptInboxItem: Identifiable, Hashable, Sendable {
    let url: URL

    var id: String { url.lastPathComponent }

    var addedAt: Date {
        let seconds = url.lastPathComponent.split(separator: "-").first.flatMap { TimeInterval($0) } ?? 0
        return Date(timeIntervalSince1970: seconds)
    }

    var digest: String {
        let name = url.deletingPathExtension().lastPathComponent
        return name.split(separator: "-").dropFirst().joined(separator: "-")
    }
}
