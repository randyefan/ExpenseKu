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

    /// Where this plan was copied from, and how much arrived — frozen at copy time,
    /// because E5's notice is about the copy, not about what the plan holds now.
    /// Nil on a plan the owner started by hand (frame I5).
    var copiedFromCycleStart: Date?
    var copiedItemCount: Int = 0
    var copiedIncomeCount: Int = 0
    /// Cleared once the owner has seen the carry-over notice, so it does not follow
    /// them around for the rest of the cycle.
    var carryOverNoticeSeen: Bool = false

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
