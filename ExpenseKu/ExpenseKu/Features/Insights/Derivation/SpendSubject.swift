//
//  SpendSubject.swift
//  ExpenseKu
//
//  What an Insights breakdown row stands for, and so what its drill-in shows
//  (docs/prd/insights-drill-in.md §4.1). Uncategorized and Unassigned are the nil
//  cases rather than entities, so they get cases of their own and can never be
//  "removed".
//

import Foundation
import SwiftData

nonisolated enum SpendSubject: Hashable {
    case category(PersistentIdentifier)
    case uncategorized
    case account(PersistentIdentifier)
    case unassigned

    var isCategory: Bool {
        switch self {
        case .category, .uncategorized: true
        case .account, .unassigned: false
        }
    }

    func matches(_ expense: Expense) -> Bool {
        switch self {
        case .category(let id): expense.category?.persistentModelID == id
        case .uncategorized: expense.category == nil
        case .account(let id): expense.account?.persistentModelID == id
        case .unassigned: expense.account == nil
        }
    }
}
