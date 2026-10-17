//
//  BankLogoSource.swift
//  ExpenseKu
//
//  Where the catalog is fetched from. Two calls, so a fetch reads every record's
//  fields cheaply and downloads only the images that changed.
//

import Foundation

nonisolated struct RemoteBankLogo: Sendable {
    let logo: BankLogo
    let recordName: String
}

nonisolated protocol BankLogoSource: Sendable {
    func fetchCatalog() async throws -> [RemoteBankLogo]
    /// A file holding the record's image, valid until the caller has copied it. Nil
    /// when the record has no image.
    func fetchImage(recordName: String) async throws -> URL?
}
