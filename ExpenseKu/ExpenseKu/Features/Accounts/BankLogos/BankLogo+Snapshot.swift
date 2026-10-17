//
//  BankLogo+Snapshot.swift
//  ExpenseKu
//
//  The catalog as it ships in the bundle, drawn until the first fetch succeeds
//  (docs/prd/bank-logos.md §6.3). Each id has an image set named `bank-logo-<id>` in
//  Assets.xcassets. Keep this list and the CloudKit records in step when a release goes
//  out; between releases the fetched catalog wins.
//

import Foundation

extension BankLogo {
    nonisolated static let snapshot: [BankLogo] = [
        BankLogo(id: "bca", displayName: "BCA", tintHex: "0060AF", sortOrder: 10),
        BankLogo(id: "bri", displayName: "BRI", tintHex: "00529C", sortOrder: 20),
        BankLogo(id: "bni", displayName: "BNI", tintHex: "F15A23", sortOrder: 30),
        BankLogo(id: "mandiri", displayName: "Mandiri", tintHex: "003D79", sortOrder: 40),
        BankLogo(id: "bsi", displayName: "BSI", tintHex: "00A39D", sortOrder: 50),
        BankLogo(id: "jago", displayName: "Bank Jago", tintHex: "E89F00", sortOrder: 60),
        BankLogo(id: "seabank", displayName: "SeaBank", tintHex: "EE5A1F", sortOrder: 70),
        BankLogo(id: "cimb-niaga", displayName: "CIMB Niaga", tintHex: "C8102E", sortOrder: 80),
        BankLogo(id: "danamon", displayName: "Danamon", tintHex: "F28C00", sortOrder: 90),
        BankLogo(id: "superbank", displayName: "Superbank", tintHex: "5B2C83", sortOrder: 100),
        BankLogo(id: "dana", displayName: "DANA", tintHex: "118EEA", sortOrder: 110),
    ]

    nonisolated var assetName: String { "bank-logo-\(id)" }
}
