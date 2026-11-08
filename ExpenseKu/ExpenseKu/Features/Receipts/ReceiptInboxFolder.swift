//
//  ReceiptInboxFolder.swift
//  ExpenseKu
//
//  The receipt inbox on disk (docs/prd/receipt-reading.md §4.1): a folder in the App
//  Group the share extension and the app both reach, on this device only. The share
//  extension compiles this same file to write into it.
//

import CryptoKit
import Foundation

nonisolated struct ReceiptInboxFolder: Sendable {
    static let appGroup = "group.randyefan.ExpenseKu"

    let url: URL

    /// The App Group's folder; without the entitlement (the unit-test host) a private
    /// one in Application Support, so the inbox still works.
    static var shared: ReceiptInboxFolder {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? URL.applicationSupportDirectory
        return ReceiptInboxFolder(url: base.appending(path: "ReceiptInbox", directoryHint: .isDirectory))
    }

    func items() -> [ReceiptInboxItem] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .map(ReceiptInboxItem.init)
            .sorted { ($0.addedAt, $0.id) < ($1.addedAt, $1.id) }
    }

    /// Adds a receipt unless one with the very same bytes is already waiting (§4.1).
    @discardableResult
    func add(_ data: Data, fileExtension: String, now: Date = .now) throws -> ReceiptInboxItem {
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        if let existing = items().first(where: { $0.digest == digest }) { return existing }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let seconds = Int(now.timeIntervalSince1970)
        let file = url.appending(path: "\(seconds)-\(digest).\(fileExtension.lowercased())")
        try data.write(to: file, options: .atomic)
        return ReceiptInboxItem(url: file)
    }

    func remove(_ item: ReceiptInboxItem) {
        try? FileManager.default.removeItem(at: item.url)
    }
}
