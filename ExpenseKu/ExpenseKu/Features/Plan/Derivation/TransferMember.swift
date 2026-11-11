//
//  TransferMember.swift
//  ExpenseKu
//
//  One plan item on a transfer line, as the line and its sheet need it
//  (docs/prd/partial-transfer.md §6.1). A value, so the sheet's derivation is testable
//  without the items, and a write still finds its item by `id`.
//

import Foundation
import SwiftData

nonisolated struct TransferMember: Identifiable, Equatable {
    let id: PersistentIdentifier
    let name: String
    let categoryName: String?
    let isAuto: Bool
    let isEnvelope: Bool
    let dueDay: Int?
    /// Where the due day falls in the line's cycle; nil when undated or unplaceable.
    let dueDate: Date?
    /// Net of paid early and set aside, as the line sums it.
    let amount: Decimal
    let createdAt: Date
    let state: PlanItemState
    let check: DoneCheckState

    var isIn: Bool { state != .todo }

    /// TO SEND's caption: "Kesehatan · Auto · Due 1".
    var caption: String {
        let kind = isEnvelope ? AppLocalization.string(.envelopeKind) : categoryName
        return [kind, isAuto ? AppLocalization.string(.auto) : nil, dueDay.map { AppLocalization.string(.due(String($0))) }]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    /// ALREADY IN's caption: the plan row's own words while Funded, "paid" once Done.
    func inCaption(accountName: String) -> String {
        switch check {
        case .autoFunded: AppLocalization.string(.coveredInCaption(accountName))
        case .funded, .envelopeFunded: PlanCopy.inAccount(accountName)
        case .setAsideMoved: AppLocalization.string(.movedToCaption(accountName))
        default: [categoryName, "paid"].compactMap(\.self).joined(separator: " · ")
        }
    }

    /// The Menu an in row offers, or nil when undoing belongs to the item's own check
    /// (a Done item's Expense, §6.3).
    var undoEntry: FundMenuEntry? {
        switch check {
        case .funded, .envelopeFunded: .notMoved
        case .autoFunded: .notCovered
        case .setAsideMoved: .setAsideUndo(hasAccount: true)
        default: nil
        }
    }

    /// Due day in cycle, the undated after, then amount ↓ · name · created
    /// (plan-sort.md §4.1, the same order PlanSections gives the plan).
    static func precedes(_ a: TransferMember, _ b: TransferMember) -> Bool {
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?) where x != y: return x < y
        case (_?, nil): return true
        case (nil, _?): return false
        default: break
        }
        if a.amount != b.amount { return a.amount > b.amount }
        if a.name != b.name { return a.name < b.name }
        return a.createdAt < b.createdAt
    }
}
