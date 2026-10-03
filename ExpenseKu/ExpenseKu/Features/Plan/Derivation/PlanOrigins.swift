//
//  PlanOrigins.swift
//  ExpenseKu
//

import Foundation
import SwiftData

nonisolated enum PlanOrigin: Equatable {
    case fixed
    case envelope(name: String)
}

nonisolated struct SpendingSplit: Equatable {
    var outsidePlan: Decimal = 0
    var fromPlan: Decimal = 0

    var total: Decimal { outsidePlan + fromPlan }

    var outsideFraction: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: outsidePlan / total).doubleValue
    }
}

nonisolated struct PlanOrigins {
    let plans: [CyclePlan]
    let payday: Int
    let calendar: Calendar

    func origin(of expense: Expense) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        guard !plans.isEmpty else { return nil }
        let cycle = PayCycle.containing(expense.date, payday: payday, calendar: calendar)
        return Self.origin(of: expense, envelopes: envelopeNames(for: cycle))
    }

    func split(_ cycleExpenses: [Expense], in cycle: PayCycle) -> SpendingSplit {
        let envelopes = envelopeNames(for: cycle)
        return cycleExpenses.reduce(into: SpendingSplit()) { split, expense in
            if Self.origin(of: expense, envelopes: envelopes) == nil {
                split.outsidePlan += expense.amount
            } else {
                split.fromPlan += expense.amount
            }
        }
    }

    func expenses(
        _ cycleExpenses: [Expense],
        in cycle: PayCycle,
        matching filter: PlanFilter
    ) -> [Expense] {
        let envelopes = envelopeNames(for: cycle)
        return cycleExpenses.filter { filter.admits(Self.origin(of: $0, envelopes: envelopes)) }
    }

    /// Expenses from any number of cycles, each judged by its own cycle's plan
    /// (insights-drill-in.md §6.1), keeping the input order.
    func expenses(_ expenses: [Expense], matching filter: PlanFilter) -> [Expense] {
        var claimsByCycle: [Date: [PersistentIdentifier: String]] = [:]
        return expenses.filter { filter.admits(origin(of: $0, claimsByCycle: &claimsByCycle)) }
    }

    /// The split of expenses from any number of cycles, each judged by its own cycle's plan.
    func split(_ expenses: [Expense]) -> SpendingSplit {
        var claimsByCycle: [Date: [PersistentIdentifier: String]] = [:]
        return expenses.reduce(into: SpendingSplit()) { split, expense in
            if origin(of: expense, claimsByCycle: &claimsByCycle) == nil {
                split.outsidePlan += expense.amount
            } else {
                split.fromPlan += expense.amount
            }
        }
    }

    private func origin(
        of expense: Expense,
        claimsByCycle: inout [Date: [PersistentIdentifier: String]]
    ) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        guard !plans.isEmpty else { return nil }
        let cycle = PayCycle.containing(expense.date, payday: payday, calendar: calendar)
        let envelopes = claimsByCycle[cycle.start] ?? envelopeNames(for: cycle)
        claimsByCycle[cycle.start] = envelopes
        return Self.origin(of: expense, envelopes: envelopes)
    }

    private func envelopeNames(for cycle: PayCycle) -> [PersistentIdentifier: String] {
        guard let plan = PlanLookup.plan(for: cycle, in: plans) else { return [:] }
        let envelopes = PlanDormancy.split(plan.items ?? []).active.filter(\.isEnvelope)
        return EnvelopeSpend.claims(in: envelopes, excluding: nil)
    }

    private static func origin(
        of expense: Expense,
        envelopes: [PersistentIdentifier: String]
    ) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        guard let category = expense.category?.persistentModelID,
              let name = envelopes[category] else { return nil }
        return .envelope(name: name)
    }
}
