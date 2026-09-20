//
//  PlanCarryOver.swift
//  ExpenseKu
//
//  A new cycle's plan starts as a full copy of the previous cycle's — every PlanItem
//  and every IncomeLine, amounts included (PRD §7.2). There is no importer and no
//  book-opening step: the owner types one cycle by hand and carry-over covers every
//  cycle after it.
//
//  What is *not* copied is the point. Doneness, the Expense link, needs-review,
//  "sudah masuk" and the transfer ticks are all facts about the cycle that just ended;
//  copying any of them would open the new cycle with work already claimed as finished.
//
//  Rows that were Rp 0 or never completed arrive dormant, folded into "From last
//  cycle". The spreadsheet keeps them deliberately — they are reminders — but they
//  accumulate: 11 dead rows by January, 18 by September. Folding keeps the reminder
//  and drops the clutter, and is the one place this should beat the spreadsheet rather
//  than copy it.
//
//  It runs from the Plan lens for the cycle actually on screen, never speculatively:
//  paging forward is what should create October's plan, not launching the app.
//

import Foundation
import SwiftData

@MainActor
enum PlanCarryOver {
    /// Copies the most recent earlier plan into `cycle`, if that cycle has none and
    /// there is something to copy. Returns the new plan, or nil when neither holds.
    @discardableResult
    static func makePlan(for cycle: PayCycle, from plans: [CyclePlan],
                         in context: ModelContext) -> CyclePlan? {
        guard PlanLookup.plan(for: cycle, in: plans) == nil,
              let source = PlanLookup.source(before: cycle, in: plans) else { return nil }

        let plan = CyclePlan(cycleStart: cycle.start)
        plan.copiedFromCycleStart = source.cycleStart
        // Only the rows that arrive *live*. Counting the dormant ones too would put
        // "25 items" in the notice directly above a list headed "PLAN · 14 ITEMS",
        // and the sentence is about what the owner is being asked to adjust. A copied
        // row is dormant exactly when its amount is zero, since doneness never travels.
        plan.copiedItemCount = (source.items ?? []).count { $0.amount > 0 }
        plan.copiedIncomeCount = (source.incomeLines ?? []).count
        context.insert(plan)

        for line in source.incomeLines ?? [] {
            context.insert(IncomeLine(
                name: line.name,
                amount: line.amount,
                // Never copied: the money has not arrived in the new cycle.
                hasArrived: false,
                createdAt: line.createdAt,
                plan: plan
            ))
        }

        for item in source.items ?? [] {
            context.insert(PlanItem(
                name: item.name,
                amount: item.amount,
                kind: item.kind,
                // A day-of-month, so it survives the copy without re-entry — which is
                // the whole reason a due day is not a date.
                dueDay: item.dueDay,
                isAuto: item.isAuto,
                lastUsedCycleStart: lastUsed(of: item, sourceCycleStart: source.cycleStart),
                carriedOver: true,
                createdAt: item.createdAt,
                plan: plan,
                category: item.category,
                account: item.account,
                people: item.people ?? [],
                envelopeCategories: item.envelopeCategories ?? []
            ))
        }

        try? context.save()
        return plan
    }

    /// When this row was last in real use: the source cycle if it was in use there,
    /// otherwise whatever the source was already carrying. That is what lets a row
    /// dormant for nine cycles still say the month it last mattered.
    static func lastUsed(of item: PlanItem, sourceCycleStart: Date) -> Date? {
        let wasInUse = item.amount > 0 || item.isDone
        return wasInUse ? sourceCycleStart : item.lastUsedCycleStart
    }
}
