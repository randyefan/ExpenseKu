//
//  BankLogoCatalog.swift
//  ExpenseKu
//
//  The bank logos the app can draw right now (docs/prd/bank-logos.md §6): the cached
//  fetch when there is one, the bundled snapshot until then. Refreshed on launch and on
//  return to the foreground, at most every ten minutes. A failed refresh changes
//  nothing, so the last good catalog keeps drawing.
//
//  Injected at the root as an optional environment value. Views without it, previews
//  above all, fall back to `fallback`, which is the snapshot alone.
//

import SwiftUI
import UIKit

@Observable
final class BankLogoCatalog {
    private(set) var logos: [BankLogo]
    private(set) var isFetched: Bool

    private var byID: [String: BankLogo] = [:]
    @ObservationIgnored private var images: [String: UIImage] = [:]
    @ObservationIgnored private var lastAttempt: Date?
    @ObservationIgnored private let source: (any BankLogoSource)?
    @ObservationIgnored private let store: BankLogoStore?

    static let fallback = BankLogoCatalog(source: nil, store: nil)

    init(source: (any BankLogoSource)?, store: BankLogoStore?) {
        self.source = source
        self.store = store
        let cached = store?.load()
        logos = BankLogoRules.ordered(cached ?? BankLogo.snapshot)
        isFetched = cached != nil
        byID = Dictionary(logos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    static func live() -> BankLogoCatalog {
        // The unsigned test host has no CloudKit entitlement, and CKContainer traps
        // without one.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return BankLogoCatalog(source: nil, store: nil)
        }
        #if DEBUG
        if let source = DebugBankLogoSource.fromLaunchArguments() {
            return BankLogoCatalog(source: source, store: BankLogoStore(directory: .temporaryDirectory.appending(path: "DebugBankLogos-\(UUID().uuidString)")))
        }
        #endif
        return BankLogoCatalog(source: CloudKitBankLogoSource(), store: .live)
    }

    func logo(for id: String?) -> BankLogo? {
        guard let id else { return nil }
        return byID[id]
    }

    func image(for logo: BankLogo) -> Image {
        if let image = images[logo.id] { return Image(uiImage: image) }
        let loaded = if isFetched, let store {
            UIImage(contentsOfFile: store.imageURL(for: logo.id).path())
        } else {
            UIImage(named: logo.assetName)
        }
        guard let loaded else { return Image(systemName: AccountAppearance.bankSymbol) }
        images[logo.id] = loaded
        return Image(uiImage: loaded)
    }

    func refreshIfDue(now: Date = .now) async {
        guard let source, let store, BankLogoRules.isDue(lastAttempt: lastAttempt, now: now) else { return }
        lastAttempt = now
        do {
            let remote = try await source.fetchCatalog().filter { BankLogoRules.isUsable($0.logo) }
            let needed = BankLogoRules.idsToDownload(cached: isFetched ? logos : [], remote: remote.map(\.logo))
            var withImages: [BankLogo] = []
            for entry in remote {
                if needed.contains(entry.logo.id) {
                    guard let file = try await source.fetchImage(recordName: entry.recordName) else { continue }
                    try store.storeImage(from: file, for: entry.logo.id)
                }
                withImages.append(entry.logo)
            }
            let fetched = BankLogoRules.ordered(withImages)
            try store.save(fetched)
            store.removeImages(except: Set(fetched.map(\.id)))
            apply(fetched, changed: needed)
        } catch {
            print("[ExpenseKu] Bank logo catalog not refreshed: \(error)")
        }
    }

    private func apply(_ fetched: [BankLogo], changed: Set<String>) {
        if !isFetched { images = [:] }
        for id in changed { images[id] = nil }
        byID = Dictionary(fetched.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        isFetched = true
        logos = fetched
    }
}
