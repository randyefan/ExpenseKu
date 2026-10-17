//
//  CloudKitBankLogoSource.swift
//  ExpenseKu
//
//  Reads `BankLogo` records from the public database of the app's CloudKit container
//  (ADR-0012). Reading the public database needs no iCloud account. The query matches
//  every record, which needs `recordName` marked Queryable in the schema; order is
//  applied on device, so no field has to be Sortable.
//

import CloudKit

nonisolated struct CloudKitBankLogoSource: BankLogoSource {
    static let recordType = "BankLogo"

    private var database: CKDatabase {
        CKContainer(identifier: "iCloud.randyefan.ExpenseKu").publicCloudDatabase
    }

    func fetchCatalog() async throws -> [RemoteBankLogo] {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        let keys = ["id", "displayName", "tint", "sortOrder"]
        var (results, cursor) = try await database.records(matching: query, desiredKeys: keys)
        var records = results.compactMap { try? $0.1.get() }
        while let next = cursor {
            (results, cursor) = try await database.records(continuingMatchFrom: next, desiredKeys: keys)
            records += results.compactMap { try? $0.1.get() }
        }
        return records.compactMap(Self.remoteLogo)
    }

    func fetchImage(recordName: String) async throws -> URL? {
        let id = CKRecord.ID(recordName: recordName)
        let results = try await database.records(for: [id], desiredKeys: ["logo"])
        let record = try results[id]?.get()
        return (record?["logo"] as? CKAsset)?.fileURL
    }

    private static func remoteLogo(_ record: CKRecord) -> RemoteBankLogo? {
        guard let id = record["id"] as? String,
              let displayName = record["displayName"] as? String else { return nil }
        let logo = BankLogo(
            id: id,
            displayName: displayName,
            tintHex: record["tint"] as? String ?? "",
            sortOrder: (record["sortOrder"] as? Int64).map(Int.init) ?? .max,
            modified: record.modificationDate
        )
        return RemoteBankLogo(logo: logo, recordName: record.recordID.recordName)
    }
}
