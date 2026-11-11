//
//  PlanSort.swift
//  ExpenseKu
//
//  The orders the plan's items can be read in (docs/prd/plan-sort.md §4).
//
//  Session view state, never stored: relaunching, paging to another cycle and the
//  Funded filter all return the plan to Amount (§5).
//

import Foundation

nonisolated enum PlanSort: CaseIterable, Identifiable, Hashable {
    case amount
    case account
    case group
    case dueDay
    case status
    case name

    var id: Self { self }

    var title: String {
        switch self {
        case .amount: AppLocalization.string(.amount)
        case .account: AppLocalization.string(.account)
        case .group: AppLocalization.string(.group)
        case .dueDay: AppLocalization.string(.dueDay)
        case .status: AppLocalization.string(.status)
        case .name: AppLocalization.string(.name)
        }
    }

    var systemImage: String {
        switch self {
        case .amount: "banknote"
        case .account: "creditcard"
        case .group: "tray.full"
        case .dueDay: "calendar"
        case .status: "checkmark.circle"
        case .name: "textformat"
        }
    }
}
