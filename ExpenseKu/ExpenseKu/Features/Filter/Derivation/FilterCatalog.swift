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

    /// "All", or the Only names then "not" and the Hidden names, each part one or two names
    /// then "+N", in the checklist's order: "Kopi, Makan, not Kos", "Not Cicilan, Kos".
    func summary(of filter: ExpenseFilter, in dimension: FilterDimension) -> String {
        values(of: filter, in: dimension, capitalisingNot: true) ?? "All"
    }

    /// "Category · not Cicilan, Kos" for one dimension; the values joined by " · " for several.
    func pillText(for filter: ExpenseFilter) -> String {
        let active = filter.activeDimensions
        let described = active.compactMap { values(of: filter, in: $0, capitalisingNot: false) }
        if active.count == 1, let only = active.first, let value = described.first {
            return "\(only.title) · \(value)"
        }
        return described.joined(separator: " · ")
    }

    private func values(of filter: ExpenseFilter, in dimension: FilterDimension, capitalisingNot: Bool) -> String? {
        let shown = names(of: filter.choices(marked: .only, in: dimension), in: dimension)
        let hidden = names(of: filter.choices(marked: .hidden, in: dimension), in: dimension)
        var parts: [String] = []
        if !shown.isEmpty { parts.append(Self.abbreviated(shown)) }
        if !hidden.isEmpty { parts.append((parts.isEmpty && capitalisingNot ? "Not " : "not ") + Self.abbreviated(hidden)) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func names(of choices: Set<FilterChoice>, in dimension: FilterDimension) -> [String] {
        options(for: dimension).filter { choices.contains($0.choice) }.map(\.name)
    }

    private static func abbreviated(_ names: [String]) -> String {
        names.count <= 2
            ? names.joined(separator: ", ")
            : names.prefix(2).joined(separator: ", ") + " +\(names.count - 2)"
    }
}
