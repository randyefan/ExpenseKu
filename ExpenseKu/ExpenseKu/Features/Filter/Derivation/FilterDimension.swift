//
//  FilterDimension.swift
//  ExpenseKu
//
//  The four things an expense can be filtered by (docs/prd/expense-filter.md §4.1), in the
//  order the sheet, the badge and the pill always use. Each knows which of its choices an
//  expense carries, including the empty value an expense falls into when it has none.
//

import Foundation
import SwiftData

nonisolated enum FilterDimension: Int, CaseIterable, Hashable, Comparable {
    case category
    case group
    case account
    case person

    static func < (lhs: FilterDimension, rhs: FilterDimension) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .category: "Category"
        case .group: "Group"
        case .account: "Account"
        case .person: "Person"
        }
    }

    var emptyName: String {
        switch self {
        case .category: "Uncategorized"
        case .group: "No group"
        case .account: "Unassigned"
        case .person: "No one"
        }
    }

    func choices(of expense: Expense) -> Set<FilterChoice> {
        switch self {
        case .category:
            [expense.category.map { .entity($0.persistentModelID) } ?? .none]
        case .group:
            [expense.category?.group.map { .entity($0.persistentModelID) } ?? .none]
        case .account:
            [expense.account.map { .entity($0.persistentModelID) } ?? .none]
        case .person:
            Self.personChoices(of: expense)
        }
    }

    private static func personChoices(of expense: Expense) -> Set<FilterChoice> {
        let people = expense.people ?? []
        guard !people.isEmpty else { return [.none] }
        return Set(people.map { .entity($0.persistentModelID) })
    }
}
