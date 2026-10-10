//
//  ExpenseFilter.swift
//  ExpenseKu
//
//  The owner's Category / Group / Account / Person filter on the Expenses tab, Insights and
//  its drill-in (docs/prd/expense-filter.md). Within a dimension an expense passes when it
//  matches any Only value, if there is one, and carries no Hidden value (§4.9); dimensions
//  combine with AND; a dimension with nothing marked does not narrow.
//
//  Held as identifiers rather than models, for PersonExpensesRoute's reason: no live
//  model sits in view state, and a deleted entity is pruned against the catalog (D8).
//

import Foundation

nonisolated struct ExpenseFilter: Hashable {
    private var marks: [FilterDimension: [FilterChoice: FilterMark]] = [:]

    var isEmpty: Bool { marks.isEmpty }

    var activeDimensions: [FilterDimension] {
        FilterDimension.allCases.filter(isActive)
    }

    func isActive(_ dimension: FilterDimension) -> Bool {
        marks[dimension] != nil
    }

    func mark(of choice: FilterChoice, in dimension: FilterDimension) -> FilterMark? {
        marks[dimension]?[choice]
    }

    func choices(marked mark: FilterMark, in dimension: FilterDimension) -> Set<FilterChoice> {
        Set((marks[dimension] ?? [:]).filter { $0.value == mark }.keys)
    }

    mutating func set(_ mark: FilterMark?, for choice: FilterChoice, in dimension: FilterDimension) {
        var marked = marks[dimension] ?? [:]
        marked[choice] = mark
        marks[dimension] = marked.isEmpty ? nil : marked
    }

    mutating func cycle(_ choice: FilterChoice, in dimension: FilterDimension) {
        set(FilterMark.after(mark(of: choice, in: dimension)), for: choice, in: dimension)
    }

    mutating func clear(_ dimension: FilterDimension) {
        marks[dimension] = nil
    }

    func dropping(_ dimension: FilterDimension?) -> ExpenseFilter {
        guard let dimension else { return self }
        var copy = self
        copy.clear(dimension)
        return copy
    }

    func keeping(where isKept: (FilterChoice, FilterDimension) -> Bool) -> ExpenseFilter {
        var copy = ExpenseFilter()
        for (dimension, marked) in marks {
            let kept = marked.filter { isKept($0.key, dimension) }
            if !kept.isEmpty { copy.marks[dimension] = kept }
        }
        return copy
    }

    func admits(_ expense: Expense) -> Bool {
        marks.allSatisfy { dimension, marked in
            let carried = dimension.choices(of: expense)
            let only = marked.filter { $0.value == .only }.keys
            let matchesOnly = only.isEmpty || only.contains(where: carried.contains)
            return matchesOnly && !carried.contains { marked[$0] == .hidden }
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
