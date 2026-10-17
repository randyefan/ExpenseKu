//
//  DebugBankLogoSource.swift
//  ExpenseKu
//
//  DEBUG-only stand-in for the public database, chosen with `-bankCatalog <scenario>`
//  so the simulator can show a fetched catalog without a CloudKit record existing:
//
//  - `fetched`            the snapshot, as if fetched
//  - `withdrawn-mandiri`  the snapshot without Mandiri (docs/prd/bank-logos.md §5.3)
//  - `empty`              no records at all, so the Banks section hides (§4)
//

#if DEBUG
import UIKit

nonisolated struct DebugBankLogoSource: BankLogoSource {
    let logos: [BankLogo]

    static func fromLaunchArguments() -> DebugBankLogoSource? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-bankCatalog"), i + 1 < args.count else { return nil }
        let fetchedAt = Date(timeIntervalSince1970: 1_790_000_000)
        let snapshot = BankLogo.snapshot.map { logo in
            var logo = logo
            logo.modified = fetchedAt
            return logo
        }
        switch args[i + 1] {
        case "fetched": return DebugBankLogoSource(logos: snapshot)
        case "withdrawn-mandiri": return DebugBankLogoSource(logos: snapshot.filter { $0.id != "mandiri" })
        case "empty": return DebugBankLogoSource(logos: [])
        default: return nil
        }
    }

    func fetchCatalog() async throws -> [RemoteBankLogo] {
        logos.map { RemoteBankLogo(logo: $0, recordName: $0.id) }
    }

    func fetchImage(recordName: String) async throws -> URL? {
        let data = await MainActor.run { UIImage(named: "bank-logo-\(recordName)")?.pngData() }
        guard let data else { return nil }
        let url = URL.temporaryDirectory.appending(path: "debug-bank-logo-\(recordName).png")
        try data.write(to: url)
        return url
    }
}
#endif
