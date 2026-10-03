//
//  SpendEntityIdentity.swift
//  ExpenseKu
//
//  The name, glyph and tint a drill-in draws its subject with. Uncategorized and
//  Unassigned borrow their Insights row's look, since no entity stands behind them.
//

import SwiftData

/// How a drill-in names and draws its subject. Nil from `resolve` when the entity was
/// deleted while the screen was pushed.
struct SpendEntityIdentity {
    let name: String
    let kind: String
    let symbol: String
    let colorHex: String?

    static func resolve(_ subject: SpendSubject, in context: ModelContext) -> SpendEntityIdentity? {
        switch subject {
        case .category(let id):
            let category: Category? = context.existingModel(for: id)
            return category.map {
                SpendEntityIdentity(name: $0.name, kind: "Category", symbol: $0.resolvedSymbol, colorHex: $0.colorHex)
            }
        case .uncategorized:
            return SpendEntityIdentity(name: "Uncategorized", kind: "Category",
                                       symbol: CategoryIcon.symbol(for: "Uncategorized"), colorHex: nil)
        case .account(let id):
            let account: Account? = context.existingModel(for: id)
            return account.map {
                SpendEntityIdentity(name: $0.name, kind: "Account", symbol: $0.resolvedSymbol, colorHex: $0.colorHex)
            }
        case .unassigned:
            return SpendEntityIdentity(name: "Unassigned", kind: "Account",
                                       symbol: Account.defaultSymbol, colorHex: nil)
        }
    }
}
