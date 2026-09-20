//
//  PlanSheet.swift
//  ExpenseKu
//
//  Which plan sheet is up, as one value driving one `.sheet(item:)`.
//
//  ExpensesView already carries four sheet modifiers on one subtree; seven more would
//  be where that breaks. One enum and one modifier also make it impossible to present
//  two at once, which stacked `isPresented` bindings cheerfully allow.
//

import Foundation

enum PlanSheet: Identifiable {
    case newPlanItem
    case editPlanItem(PlanItem)
    case newIncomeLine
    case editIncomeLine(IncomeLine)
    case transferAdjustment(accountID: PersistentIdentifier)
    /// Ticking Done: the compact confirmation that turns a plan item into an expense.
    case confirmDone(PlanItem)
    case review

    var id: String {
        switch self {
        case .newPlanItem: "newPlanItem"
        case .editPlanItem(let item): "editPlanItem-\(item.persistentModelID)"
        case .newIncomeLine: "newIncomeLine"
        case .editIncomeLine(let line): "editIncomeLine-\(line.persistentModelID)"
        case .transferAdjustment(let id): "transferAdjustment-\(id)"
        case .confirmDone(let item): "confirmDone-\(item.persistentModelID)"
        case .review: "review"
        }
    }
}

import SwiftData

/// A destructive confirmation waiting on the owner. Both of these delete something,
/// and each names exactly what (frames I4 and I7).
enum PlanConfirmation: Identifiable {
    /// Un-ticking Done deletes the Expense it created (§7.3). Unlinking without
    /// deleting was rejected: the orphan would keep counting in its envelope and in
    /// every cycle total.
    case untick(PlanItem)
    /// Deleting the item leaves its Expense alone (§9.4, ADR-0001).
    case deleteItem(PlanItem)

    var id: String {
        switch self {
        case .untick(let item): "untick-\(item.persistentModelID)"
        case .deleteItem(let item): "deleteItem-\(item.persistentModelID)"
        }
    }

    var item: PlanItem {
        switch self {
        case .untick(let item), .deleteItem(let item): item
        }
    }
}
