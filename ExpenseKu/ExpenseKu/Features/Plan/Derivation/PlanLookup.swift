//
//  PlanLookup.swift
//  ExpenseKu
//
//  Finding the plan for a cycle in the one `[CyclePlan]` the Expenses tab queries.
//
//  A plan stores its cycle's `start`, because the cycle anchor is Payday — an
//  NSUbiquitousKeyValueStore value, not a model, so there is no cycle entity to point
//  at (PRD §5). That works until the owner changes their Monthly Start Date: every
//  stored `cycleStart` then stops equalling any current `cycle.start`, and every plan
//  they have ever built disappears at once.
//
//  So the match is not equality. An exact hit wins; failing that, a plan whose start
//  falls anywhere inside the cycle is adopted, which re-homes existing plans onto the
//  new anchor instead of stranding them. Nothing is rewritten — the adoption is
//  re-derived on every read, so restoring the old payday restores the old pairing.
//

import Foundation

nonisolated enum PlanLookup {
    /// The plan for `cycle`, if one exists. Ties break on the earliest `cycleStart`,
    /// so two devices that each created a plan for the same cycle agree on which one
    /// is showing until `PlanMaintenance` folds them.
    static func plan(for cycle: PayCycle, in plans: [CyclePlan]) -> CyclePlan? {
        if let exact = plans.filter({ $0.cycleStart == cycle.start })
            .min(by: { $0.cycleStart < $1.cycleStart }) {
            return exact
        }
        return plans.filter { cycle.contains($0.cycleStart) }
            .min { $0.cycleStart < $1.cycleStart }
    }

    /// The most recent plan strictly before `cycle` — what carry-over copies from.
    /// Skips gaps, so paging two cycles ahead still copies the last real plan rather
    /// than finding nothing.
    static func source(before cycle: PayCycle, in plans: [CyclePlan]) -> CyclePlan? {
        plans.filter { $0.cycleStart < cycle.start }
            .max { $0.cycleStart < $1.cycleStart }
    }

    /// The oldest plan's start, for `CyclePaging.canGoBack`. A cycle holding only a
    /// plan and no expenses must still be reachable.
    static func oldestStart(in plans: [CyclePlan]) -> Date? {
        plans.map(\.cycleStart).min()
    }
}
