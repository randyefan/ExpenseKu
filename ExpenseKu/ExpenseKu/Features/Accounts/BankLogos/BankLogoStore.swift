//
//  BankLogoStore.swift
//  ExpenseKu
//
//  The fetched catalog on disk: the list as JSON and one PNG per logo, under
//  Application Support and kept out of backups. Its absence means the app has never
//  fetched, and the bundled snapshot applies (docs/prd/bank-logos.md §6.3). Not Caches:
//  iOS purges that, and every purge put the bundled logos back until the next fetch.
//

import UIKit

nonisolated struct BankLogoStore: Sendable {
    let directory: URL

    static let live = BankLogoStore(directory: .applicationSupportDirectory.appending(path: "BankLogos"))

    private var listURL: URL { directory.appending(path: "catalog.json") }

    func imageURL(for id: String) -> URL {
        directory.appending(path: "\(id).png")
    }

    /// Nil when nothing was ever saved, or what was saved cannot be read.
    func load() -> [BankLogo]? {
        guard let data = try? Data(contentsOf: listURL) else { return nil }
        return try? JSONDecoder().decode([BankLogo].self, from: data)
    }

    func hasImage(for id: String) -> Bool {
        FileManager.default.fileExists(atPath: imagePath(for: id))
    }

    func loadImage(for id: String) -> UIImage? {
        UIImage(contentsOfFile: imagePath(for: id))
    }

    private func imagePath(for id: String) -> String {
        imageURL(for: id).path(percentEncoded: false)
    }

    func save(_ logos: [BankLogo]) throws {
        try createDirectory()
        try JSONEncoder().encode(logos).write(to: listURL, options: .atomic)
    }

    func storeImage(from source: URL, for id: String) throws {
        try createDirectory()
        let target = imageURL(for: id)
        try? FileManager.default.removeItem(at: target)
        try FileManager.default.copyItem(at: source, to: target)
    }

    private func createDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var excluded = directory
        try excluded.setResourceValues(values)
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
