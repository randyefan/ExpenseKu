//
//  FilterCatalog+Models.swift
//  ExpenseKu
//
//  Builds the catalog from the store's entities, so the derivation itself never holds a
//  model.
//

import Foundation
import SwiftData

extension FilterCatalog {
    init(categories: [Category], groups: [CategoryGroup], accounts: [Account], people: [Person]) {
        self.init(
            categories: categories.map {
                FilterOption(choice: .entity($0.persistentModelID), name: $0.name,
                             symbol: $0.resolvedSymbol, colorHex: $0.colorHex)
            },
            groups: groups.map {
                FilterOption(choice: .entity($0.persistentModelID), name: $0.name,
                             symbol: $0.resolvedSymbol, colorHex: $0.colorHex)
            },
            accounts: accounts.map {
                FilterOption(choice: .entity($0.persistentModelID), name: $0.name,
                             symbol: $0.resolvedSymbol, colorHex: $0.colorHex, brandID: $0.brandID)
            },
            people: people.map {
                FilterOption(choice: .entity($0.persistentModelID), name: $0.name, colorHex: $0.colorHex)
            }
        )
    }
}
