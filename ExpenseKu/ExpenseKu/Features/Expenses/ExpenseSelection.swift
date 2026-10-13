//
//  ExpenseSelection.swift
//  ExpenseKu
//
//  The List lens's Select mode (docs/prd/envelope-assignment.md §4.6, §5.1): which
//  expenses are checked, and what Select All means.
//
//  Select All takes what the owner can *see* — the rows the plan and expense filters
//  leave — never the whole cycle, and never a row a Fixed item created, which is
//  already From plan and cannot be moved. A filter change that drops a checked row
//  drops it from the selection too, so the count never names rows off screen.
//

import Foundation
import SwiftData

nonisolated struct ExpenseSelection: Equatable {
    private(set) var ids: Set<PersistentIdentifier> = []

    var count: Int { ids.count }
    var isEmpty: Bool { ids.isEmpty }

    static func isSelectable(_ expense: Expense) -> Bool {
        expense.planItem == nil
    }

    func contains(_ expense: Expense) -> Bool {
        ids.contains(expense.persistentModelID)
    }

    mutating func toggle(_ expense: Expense) {
        guard Self.isSelectable(expense) else { return }
        let id = expense.persistentModelID
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
    }

    func isAllSelected(of visible: [Expense]) -> Bool {
        let selectable = visible.filter(Self.isSelectable)
        return !selectable.isEmpty && selectable.allSatisfy(contains)
    }

    /// Select All, or Deselect All once everything visible is already checked.
    mutating func toggleAll(of visible: [Expense]) {
        if isAllSelected(of: visible) {
            ids = []
        } else {
            ids = Set(visible.filter(Self.isSelectable).map(\.persistentModelID))
        }
    }

    mutating func keepOnly(_ visible: [Expense]) {
        ids.formIntersection(visible.map(\.persistentModelID))
    }

    func expenses(in visible: [Expense]) -> [Expense] {
        visible.filter(contains)
    }
}
