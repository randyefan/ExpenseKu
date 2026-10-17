//
//  BankLogoRules.swift
//  ExpenseKu
//
//  The catalog's pure rules (docs/prd/bank-logos.md §4, §6.2): the order of the Banks
//  section, what the icon search matches, which images a fetch has to download, and
//  when the next fetch is due.
//
//  The whole catalog is fetched every time because a public-database query cannot
//  report a deleted record; diffing against the cached list is how a withdrawn logo
//  is noticed. Ids double as file names in the cache, so an id that is not a plain
//  slug is dropped rather than trusted.
//

import Foundation

nonisolated enum BankLogoRules {
    static let refreshInterval: TimeInterval = 10 * 60

    /// Catalog order, one entry per id, slug ids only.
    static func ordered(_ logos: [BankLogo]) -> [BankLogo] {
        var seen: Set<String> = []
        return logos
            .filter(isUsable)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            .filter { seen.insert($0.id).inserted }
    }

    static func matching(_ logos: [BankLogo], query: String) -> [BankLogo] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return logos }
        return logos.filter { $0.displayName.localizedStandardContains(query) }
    }

    /// The ids whose image is missing from the cache or older than the record.
    static func idsToDownload(cached: [BankLogo], remote: [BankLogo]) -> Set<String> {
        let cachedDates = Dictionary(cached.map { ($0.id, $0.modified) }, uniquingKeysWith: { first, _ in first })
        return Set(remote.filter { logo in
            guard let cachedDate = cachedDates[logo.id] else { return true }
            return cachedDate == nil || cachedDate != logo.modified
        }.map(\.id))
    }

    static func isDue(lastAttempt: Date?, now: Date) -> Bool {
        guard let lastAttempt else { return true }
        return now.timeIntervalSince(lastAttempt) >= refreshInterval
    }

    static func isUsable(_ logo: BankLogo) -> Bool {
        !logo.id.isEmpty && logo.id.allSatisfy { $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }
            && !logo.displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
