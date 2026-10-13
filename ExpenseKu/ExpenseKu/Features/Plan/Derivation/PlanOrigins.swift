//
//  PlanOrigins.swift
//  ExpenseKu
//

import Foundation
import SwiftData

nonisolated enum PlanOrigin: Equatable {
    case fixed
    case envelope(name: String)
    case paidEarly(name: String, label: PaidEarlyLabel)

    /// Paid early is tagged but Outside plan: this cycle's plan never held it (§4.10.1).
    var isFromPlan: Bool {
        if case .paidEarly = self { return false }
        return true
    }
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
        return origin(of: expense, claims: claims(for: cycle))
    }

    func split(_ cycleExpenses: [Expense], in cycle: PayCycle) -> SpendingSplit {
        let cycleClaims = claims(for: cycle)
        return cycleExpenses.reduce(into: SpendingSplit()) { split, expense in
            if origin(of: expense, claims: cycleClaims)?.isFromPlan != true {
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
        return cycleExpenses.filter { filter.admits(origin(of: $0, claims: cycleClaims)) }
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
            if origin(of: expense, claimsByCycle: &claimsByCycle)?.isFromPlan != true {
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
        return origin(of: expense, claims: cycleClaims)
    }

    /// The cycle whose envelopes a row's "Move to envelope…" offers (envelope-assignment.md
    /// §4.8, §4.10.2): the expense's own, or nil when neither it nor a later cycle on offer
    /// has an active envelope, or a Fixed item created the expense.
    func moveTarget(for expense: Expense, now: Date) -> PayCycle? {
        guard ExpenseSelection.isSelectable(expense) else { return nil }
        let cycle = PayCycle.containing(expense.date, payday: payday, calendar: calendar)
        let offer = EnvelopeOffer(cycle: cycle, plans: plans, payday: payday, calendar: calendar, now: now)
        return offer.isEmpty ? nil : cycle
    }

    /// The active envelopes of the cycle's own plan, which is also the set an
    /// assignment must belong to for it to count there.
    func claims(for cycle: PayCycle) -> EnvelopeClaims {
        EnvelopeClaims(envelopes: EnvelopeOffer.activeEnvelopes(of: PlanLookup.plan(for: cycle, in: plans)),
                       cycle: cycle)
    }

    private func origin(of expense: Expense, claims: EnvelopeClaims) -> PlanOrigin? {
        if expense.planItem != nil { return .fixed }
        if let envelope = claims.envelope(for: expense) { return .envelope(name: envelope.name) }
        guard let target = claims.paidEarlyTarget(of: expense), let start = target.plan?.cycleStart else { return nil }
        let targetCycle = PayCycle.containing(start, payday: payday, calendar: calendar)
        return .paidEarly(name: target.name,
                          label: PaidEarlyLabel(target: targetCycle, from: claims.cycle, calendar: calendar))
    }
}
