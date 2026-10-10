//
//  FilterMark.swift
//  ExpenseKu
//
//  What a ticked checklist value does (docs/prd/expense-filter.md §4.9): Only keeps the
//  expenses that match it, Hidden removes the ones that carry it. A tap cycles a value
//  Off → Only → Hidden → Off.
//

import Foundation

nonisolated enum FilterMark: Hashable {
    case only
    case hidden

    static func after(_ mark: FilterMark?) -> FilterMark? {
        switch mark {
        case nil: .only
        case .only: .hidden
        case .hidden: nil
        }
    }
}
