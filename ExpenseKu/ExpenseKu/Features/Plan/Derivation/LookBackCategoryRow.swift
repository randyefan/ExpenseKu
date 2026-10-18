//
//  LookBackCategoryRow.swift
//  ExpenseKu
//
//  The reviewed cycle's Outside plan spending in one Category (look-back.md §5.2).
//

import Foundation
import SwiftData

nonisolated struct LookBackCategoryRow: Identifiable {
    enum Status: Equatable {
        /// Nothing here claims it. `fixedUse` names the Fixed items that carry it, since
        /// a Fixed item claims no Category and the owner could plan the cost twice.
        case open(fixedUse: String?)
        case claimed(envelope: String)
        case uncategorized
    }

    let category: Category?
    let total: Decimal
    let count: Int
    let status: Status

    var id: LookBackRowID { .category(category?.persistentModelID) }

    var name: String { category?.name ?? LookBackCopy.uncategorized }

    var canAdd: Bool {
        if case .open = status { return true }
        return false
    }

    var caption: String? {
        switch status {
        case .open(let fixedUse): fixedUse
        case .claimed(let envelope): LookBackCopy.claimedHere(envelope)
        case .uncategorized: LookBackCopy.categoriseFirst
        }
    }
}
