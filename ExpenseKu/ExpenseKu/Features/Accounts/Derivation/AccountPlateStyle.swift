//
//  AccountPlateStyle.swift
//  ExpenseKu
//
//  The plain values an Account's plate draws from (docs/prd/bank-logos.md §5.6.1), so
//  a derived row like a transfer line can carry its Account's look without holding
//  the model.
//

import Foundation

nonisolated struct AccountPlateStyle: Equatable {
    let name: String
    let symbol: String
    let colorHex: String?
    let brandID: String?

    init(name: String, symbol: String, colorHex: String?, brandID: String?) {
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.brandID = brandID
    }

    init(account: Account) {
        self.init(name: account.name, symbol: account.resolvedSymbol,
                  colorHex: account.colorHex, brandID: account.brandID)
    }
}
