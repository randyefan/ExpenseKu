//
//  PlanFilter.swift
//  ExpenseKu
//
//  Which half of the cycle's Outside plan / From plan split the List and Month lenses
//  show (docs/prd/plan-filter.md). Nil is All. The halves are exactly the ones
//  `PlanOrigins` draws the header split and the row tags from, so a filtered list always
//  adds up to the lit legend figure.
//

import Foundation

nonisolated enum PlanFilter: Hashable, CaseIterable {
    case outsidePlan
    case fromPlan

    /// Tapping the lit half clears the filter; tapping the other half switches to it.
    static func tapping(_ tapped: PlanFilter, on current: PlanFilter?) -> PlanFilter? {
        tapped == current ? nil : tapped
    }

    /// The legend is the only way to clear a filter, so it stays while one is on even
    /// after the plan's spending falls to zero.
    static func showsLegend(for split: SpendingSplit, filter: PlanFilter?) -> Bool {
        split.fromPlan > 0 || filter != nil
    }

    func admits(_ origin: PlanOrigin?) -> Bool {
        switch self {
        case .outsidePlan: origin == nil
        case .fromPlan: origin != nil
        }
    }

    var title: String {
        switch self {
        case .outsidePlan: "Outside plan"
        case .fromPlan: "From plan"
        }
    }

    var pillTitle: String { "\(title) only" }

    var emptyCycleTitle: String { "Nothing \(phrase)" }

    func emptyCycleDetail(span: String) -> String {
        "No expenses \(phrase) in \(span)."
    }

    func emptyDayTitle(dayPhrase: String) -> String {
        "Nothing \(phrase) \(dayPhrase)"
    }

    var emptyDayDetail: String { "Tap \(title) again to show every expense." }

    var emptyPeriodMessage: String { "Nothing \(phrase) in this period." }

    var phrase: String {
        switch self {
        case .outsidePlan: "outside the plan"
        case .fromPlan: "from the plan"
        }
    }
}
