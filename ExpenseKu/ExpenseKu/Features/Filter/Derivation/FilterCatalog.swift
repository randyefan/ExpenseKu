//
//  FilterCatalog.swift
//  ExpenseKu
//
//  Everything the filter can offer, and every word it says about a choice
//  (docs/prd/expense-filter.md §4.3, §4.4): each dimension's options by name with its
//  empty value last, the summary a sheet row and the pill print, and the pruning that
//  drops a choice whose entity was deleted.
//

import Foundation

nonisolated struct FilterCatalog {
    private let optionsByDimension: [FilterDimension: [FilterOption]]

    init(
        categories: [FilterOption] = [],
        groups: [FilterOption] = [],
        accounts: [FilterOption] = [],
        people: [FilterOption] = []
    ) {
        let entities: [FilterDimension: [FilterOption]] = [
            .category: categories, .group: groups, .account: accounts, .person: people,
        ]
        optionsByDimension = entities.reduce(into: [:]) { result, entry in
            let sorted = entry.value.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            result[entry.key] = sorted + [FilterOption(choice: .none, name: entry.key.emptyName)]
        }
    }

    func options(for dimension: FilterDimension) -> [FilterOption] {
        optionsByDimension[dimension] ?? []
    }

    func pruning(_ filter: ExpenseFilter) -> ExpenseFilter {
        filter.keeping { choice, dimension in
            options(for: dimension).contains { $0.choice == choice }
        }
    }

    /// "All", one name, two names, or two names and "+N", in the checklist's order.
    func summary(of filter: ExpenseFilter, in dimension: FilterDimension) -> String {
        let chosen = filter.choices(in: dimension)
        let names = options(for: dimension).filter { chosen.contains($0.choice) }.map(\.name)
        switch names.count {
        case 0: return "All"
        case 1, 2: return names.joined(separator: ", ")
        default: return names.prefix(2).joined(separator: ", ") + " +\(names.count - 2)"
        }
    }

    /// "Category · Makan, Kopi" for one dimension; the values joined by " · " for several.
    func pillText(for filter: ExpenseFilter) -> String {
        let active = filter.activeDimensions
        if active.count == 1, let only = active.first {
            return "\(only.title) · \(summary(of: filter, in: only))"
        }
        return active.map { summary(of: filter, in: $0) }.joined(separator: " · ")
    }
}
