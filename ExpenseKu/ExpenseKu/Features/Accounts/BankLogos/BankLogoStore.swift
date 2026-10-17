//
//  BankLogoStore.swift
//  ExpenseKu
//
//  The fetched catalog on disk: the list as JSON and one PNG per logo, under Caches.
//  Its absence means the app has never fetched, and the bundled snapshot applies
//  (docs/prd/bank-logos.md §6.3). If iOS purges Caches the app falls back to the
//  snapshot until the next fetch, which is the state it shipped in.
//

import Foundation

nonisolated struct BankLogoStore: Sendable {
    let directory: URL

    static let live = BankLogoStore(directory: .cachesDirectory.appending(path: "BankLogos"))

    private var listURL: URL { directory.appending(path: "catalog.json") }

    func imageURL(for id: String) -> URL {
        directory.appending(path: "\(id).png")
    }

    /// Nil when nothing was ever saved, or what was saved cannot be read.
    func load() -> [BankLogo]? {
        guard let data = try? Data(contentsOf: listURL) else { return nil }
        return try? JSONDecoder().decode([BankLogo].self, from: data)
    }

    func save(_ logos: [BankLogo]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(logos).write(to: listURL, options: .atomic)
    }

    func storeImage(from source: URL, for id: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let target = imageURL(for: id)
        try? FileManager.default.removeItem(at: target)
        try FileManager.default.copyItem(at: source, to: target)
    }

    func removeImages(except ids: Set<String>) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "png" {
            if !ids.contains(file.deletingPathExtension().lastPathComponent) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
