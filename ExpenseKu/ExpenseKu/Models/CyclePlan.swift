//
//  CyclePlan.swift
//  ExpenseKu
//
//  The owner's allocation of one pay cycle's income: what is owed, what it is for,
//  and what is left. Exactly one per pay cycle (docs/prd/payday-planning.md §5).
//
//  Keyed by `cycleStart` rather than by a relationship, because the cycle anchor is
//  `Payday` — an NSUbiquitousKeyValueStore value, not a SwiftData model, so there is
//  nothing to point at. Always derive the key with `PayCycle.containing(_:payday:)`;
//  a hand-rolled date misses the short-month clamp and silently orphans the plan.
//
//  The child relationships cascade, which ADR-0001 permits: that decision is about
//  deletes never destroying an Expense, and a plan's items and income lines have no
//  meaning outside their plan. The link that reaches the ledger is PlanItem's
//  `linkedExpenses`, and that one nullifies.
//

import Foundation
import SwiftData

@Model
final class CyclePlan {
    /// The owning cycle's `PayCycle.start`, at the start of that day.
    var cycleStart: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \IncomeLine.plan)
    var incomeLines: [IncomeLine]? = []

    @Relationship(deleteRule: .cascade, inverse: \PlanItem.plan)
    var items: [PlanItem]? = []

    @Relationship(deleteRule: .cascade, inverse: \TransferLine.plan)
    var transferLines: [TransferLine]? = []

    init(cycleStart: Date = .now) {
        self.cycleStart = cycleStart
    }
}
