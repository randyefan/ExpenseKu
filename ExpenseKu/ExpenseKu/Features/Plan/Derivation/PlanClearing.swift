//
//  PlanClearing.swift
//  ExpenseKu
//
//  Clearing an upcoming cycle's plan (docs/prd/clear-plan.md). The plan is deleted and
//  its cycle goes back to having none, so the owner can copy afresh or start blank.
//
//  Only a cycle that has not started yet can be cleared: the current and past plans hold
//  what actually happened, and their Done items are the ledger's own expenses.
//
//  The confirmation counts what reaches outside the plan before it goes. Every one of
//  those links nullifies (ADR-0001), so no Expense is lost, but an expense paid early
//  falls back to Outside plan and a December set-aside loses its target, and the owner
//  should read that before tapping, not discover it after.
//

import Foundation
import SwiftData

nonisolated enum PlanClearing {
    struct Reach: Equatable {
        var items = 0
        var dormant = 0
        var incomeLines = 0
        var paidEarly = 0
        var done = 0
        var setAsides = 0
        var setAsideMonths: [String] = []

        var linkCount: Int { paidEarly + done + setAsides }
        var touchesExpenses: Bool { paidEarly + done > 0 }
    }

    static func canClear(_ plan: CyclePlan?, cycle: PayCycle, today: Date, payday: Int,
                         calendar: Calendar) -> Bool {
        guard plan != nil else { return false }
        return cycle.start > PayCycle.containing(today, payday: payday, calendar: calendar).start
    }

    static func reach(of plan: CyclePlan, payday: Int, calendar: Calendar) -> Reach {
        let items = plan.items ?? []
        let envelopes = items.filter(\.isEnvelope)
        let assigned = Set(envelopes.flatMap { $0.assignedExpenses ?? [] }.map(\.persistentModelID))
        let done = Set(items.flatMap { $0.linkedExpenses ?? [] }.map(\.persistentModelID))
        let setAsides = envelopes.flatMap { SetAside.sources(into: $0) }
            .filter { $0.plan?.persistentModelID != plan.persistentModelID }
        let dormant = items.count(where: PlanDormancy.isDormant)
        return Reach(
            items: items.count - dormant,
            dormant: dormant,
            incomeLines: (plan.incomeLines ?? []).count,
            paidEarly: assigned.count,
            done: done.count,
            setAsides: setAsides.count,
            setAsideMonths: SetAside.months(of: setAsides, payday: payday, calendar: calendar)
        )
    }

    static func title(month: String) -> String {
        AppLocalization.string(.clearSPlan(month))
    }

    static func message(_ reach: Reach) -> String {
        [deletedSentence(reach), linkSentence(reach), reach.touchesExpenses ? AppLocalization.string(.expensesAreKept) : nil]
            .compactMap(\.self)
            .joined(separator: " ")
    }

    private static func deletedSentence(_ reach: Reach) -> String {
        let parts = [
            reach.items > 0 ? PlanCopy.counted(reach.items, .item) : nil,
            reach.dormant > 0 ? AppLocalization.string(.planDormantCount(reach.dormant)) : nil,
            reach.incomeLines > 0 ? PlanCopy.counted(reach.incomeLines, .incomeLine) : nil
        ].compactMap(\.self)
        guard !parts.isEmpty else { return AppLocalization.string(.thePlanWillBeDeleted) }
        return AppLocalization.string(.planClearedParts(listed(parts)))
    }

    private static func linkSentence(_ reach: Reach) -> String? {
        let parts = [
            reach.paidEarly > 0 ? AppLocalization.string(.planEarlyExpenseCount(reach.paidEarly)) : nil,
            reach.done > 0 ? AppLocalization.string(.planDoneExpenseCount(reach.done)) : nil,
            reach.setAsides > 0 ? AppLocalization.string(.planSetAsideSourceCount(reach.setAsides, setAsideSource(reach))) : nil
        ].compactMap(\.self)
        guard !parts.isEmpty else { return nil }
        return AppLocalization.string(reach.linkCount == 1
                      ? .planClearedLinks(listed(parts)) : .planClearedLinksPlural(listed(parts)))
    }

    private static func listed(_ parts: [String]) -> String {
        guard let last = parts.last else { return "" }
        return parts.count == 1 ? last
            : AppLocalization.string(.listFinalNoComma(parts.dropLast().joined(separator: ", "), last))
    }

    private static func setAsideSource(_ reach: Reach) -> String {
        reach.setAsideMonths.count == 1 ? reach.setAsideMonths[0] : AppLocalization.string(.earlierCycles)
    }
}
