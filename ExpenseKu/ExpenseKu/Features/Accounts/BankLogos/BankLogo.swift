//
//  BankLogo.swift
//  ExpenseKu
//
//  One entry of the developer's bank-logo catalog (docs/prd/bank-logos.md §6.1): the
//  id an Account stores, the name the picker searches, the brand colour an Auto tint
//  starts from, and the position in the Banks section. The image lives beside it,
//  in the asset catalog for the bundled snapshot or on disk once fetched.
//

import Foundation

nonisolated struct BankLogo: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let displayName: String
    let tintHex: String
    let sortOrder: Int
    /// The CloudKit record's modification date. Nil for snapshot entries, which never
    /// need re-downloading.
    var modified: Date? = nil
}
