//
//  ExpenseFilter.swift
//  ExpenseKu
//
//  The owner's Category / Group / Account / Person filter on the Expenses tab, Insights and
//  its drill-in (docs/prd/expense-filter.md). Choices in one dimension match any of them;
//  dimensions combine with AND; a dimension with nothing chosen does not narrow.
//
//  Held as identifiers rather than models, for PersonExpensesRoute's reason: no live
//  model sits in view state, and a deleted entity is pruned against the catalog (D8).
//

import Foundation

nonisolated struct ExpenseFilter: Hashable {
    private var selections: [FilterDimension: Set<FilterChoice>] = [:]

    var isEmpty: Bool { selections.isEmpty }

    var activeDimensions: [FilterDimension] {
        FilterDimension.allCases.filter { selections[$0] != nil }
    }

    func choices(in dimension: FilterDimension) -> Set<FilterChoice> {
        selections[dimension] ?? []
    }

    func contains(_ choice: FilterChoice, in dimension: FilterDimension) -> Bool {
        selections[dimension]?.contains(choice) ?? false
    }

    mutating func toggle(_ choice: FilterChoice, in dimension: FilterDimension) {
        var chosen = selections[dimension] ?? []
        if chosen.remove(choice) == nil { chosen.insert(choice) }
        selections[dimension] = chosen.isEmpty ? nil : chosen
    }

    mutating func clear(_ dimension: FilterDimension) {
        selections[dimension] = nil
    }

    func dropping(_ dimension: FilterDimension?) -> ExpenseFilter {
        guard let dimension else { return self }
        var copy = self
        copy.clear(dimension)
        return copy
    }

    func keeping(where isKept: (FilterChoice, FilterDimension) -> Bool) -> ExpenseFilter {
        var copy = ExpenseFilter()
        for (dimension, chosen) in selections {
            let kept = chosen.filter { isKept($0, dimension) }
            if !kept.isEmpty { copy.selections[dimension] = kept }
        }
        return copy
    }

    func admits(_ expense: Expense) -> Bool {
        selections.allSatisfy { dimension, chosen in
            !dimension.choices(of: expense).isDisjoint(with: chosen)
        }
    }

    func expenses(_ expenses: [Expense]) -> [Expense] {
        isEmpty ? expenses : expenses.filter(admits)
    }

    /// The Filter button's badge: every active dimension, and the plan filter when it is on
    /// (§4.8), since the sheet sets both.
    func activeCount(planFilter: PlanFilter?) -> Int {
        activeDimensions.count + (planFilter == nil ? 0 : 1)
    }

    /// The figure under the hero: the unfiltered total, only while a filter is on (§4.5).
    func ofTotal(_ whole: Decimal) -> Decimal? {
        isEmpty ? nil : whole
    }
}
