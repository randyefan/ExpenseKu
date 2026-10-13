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
        return Self.origin(of: expense, claims: claims(for: cycle))
    }

    func split(_ cycleExpenses: [Expense], in cycle: PayCycle) -> SpendingSplit {
        let cycleClaims = claims(for: cycle)
        return cycleExpenses.reduce(into: SpendingSplit()) { split, expense in
            if Self.origin(of: expense, claims: cycleClaims) == nil {
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
        let cycleClaims = claims(for: cycle)
        return cycleExpenses.filter { filter.admits(Self.origin(of: $0, claims: cycleClaims)) }
    }

    /// Expenses from any number of cycles, each judged by its own cycle's plan
    /// (insights-drill-in.md §6.1), keeping the input order.
    func expenses(_ expenses: [Expense], matching filter: PlanFilter) -> [Expense] {
        var claimsByCycle: [Date: EnvelopeClaims] = [:]
        return expenses.filter { filter.admits(origin(of: $0, claimsByCycle: &claimsByCycle)) }
    }

    /// The split of expenses from any number of cycles, each judged by its own cycle's plan.
    func split(_ expenses: [Expense]) -> SpendingSplit {
        var claimsByCycle: [Date: EnvelopeClaims] = [:]
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
        claimsByCycle: inout [Date: EnvelopeClaims]
    ) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        guard !plans.isEmpty else { return nil }
        let cycle = PayCycle.containing(expense.date, payday: payday, calendar: calendar)
        let cycleClaims = claimsByCycle[cycle.start] ?? claims(for: cycle)
        claimsByCycle[cycle.start] = cycleClaims
        return Self.origin(of: expense, claims: cycleClaims)
    }

    /// The active envelopes of the cycle's own plan, which is also the set an
    /// assignment must belong to for it to count.
    func claims(for cycle: PayCycle) -> EnvelopeClaims {
        guard let plan = PlanLookup.plan(for: cycle, in: plans) else { return EnvelopeClaims(envelopes: []) }
        return EnvelopeClaims(envelopes: PlanDormancy.split(plan.items ?? []).active.filter(\.isEnvelope))
    }

    private static func origin(of expense: Expense, claims: EnvelopeClaims) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        return claims.envelope(for: expense).map { .envelope(name: $0.name) }
    }
}
