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
        case .category: AppLocalization.string(.category)
        case .group: AppLocalization.string(.group)
        case .account: AppLocalization.string(.account)
        case .person: AppLocalization.string(.person)
        }
    }

    var emptyName: String {
        switch self {
        case .category: AppLocalization.string(.uncategorized)
        case .group: AppLocalization.string(.noGroup)
        case .account: AppLocalization.string(.unassigned)
        case .person: AppLocalization.string(.noOne)
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
