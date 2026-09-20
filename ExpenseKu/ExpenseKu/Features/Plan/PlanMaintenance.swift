//
//  PlanMaintenance.swift
//  ExpenseKu
//
//  The repair-and-materialise pass, run at launch and on every CloudKit remote change
//  beside `Person.reconcileMe` — which is the pattern this file is written after, and
//  worth reading first.
//
//  It does three things, all idempotent and all silent when there is nothing to do:
//
//  **Materialise Auto items.** A PlanItem marked Auto with a due day creates its own
//  Expense at the planned amount, without confirmation (ADR-0007). Materialisation is
//  lazy, not scheduled: iOS does not run the app in the background for this, so the
//  Expense appears the first time the app is opened after the due day passes. Five days
//  away produces five at once, which is why the review notice is written for a burst.
//
//  **Fold twin expenses.** Two devices that both open the app after a due day and
//  before they sync will both see no linked expense and both write one. That is the
//  same hazard `reconcileMe` guards, against a store that cannot enforce uniqueness
//  (ADR-0002), and it is the only reason `linkedExpenses` is a to-many rather than a
//  to-one: a to-one lets last-writer-wins orphan the loser, where a to-many leaves the
//  duplicate visible so it can be folded.
//
//  **Fold twin plans**, for the same reason, one level up.
//
//  Deleting rows from the ledger is not something to do casually, so the fold is
//  deliberately narrow: it only ever removes an expense that is linked to the *same
//  PlanItem* as a survivor and is flagged needs-review — which by construction means
//  this code wrote both of them, automatically, for one item. An expense the owner
//  confirmed by hand is never touched.
//

import Foundation
import SwiftData

@MainActor
enum PlanMaintenance {
    static func run(in context: ModelContext, now: Date = .now,
                    payday: Int = Payday.current, calendar: Calendar = .current) {
        guard let plans = try? context.fetch(FetchDescriptor<CyclePlan>()) else { return }
        dedupePlans(plans, in: context)
        materialiseAutoItems(in: plans, context: context, now: now,
                             payday: payday, calendar: calendar)
        foldTwinExpenses(in: plans, context: context)

        // Only save when something actually changed. This also runs from the remote
        // change handler, and a launch with nothing to do must not start a sync storm.
        if context.hasChanges { try? context.save() }
    }

    // MARK: - Materialisation

    private static func materialiseAutoItems(
        in plans: [CyclePlan], context: ModelContext, now: Date, payday: Int, calendar: Calendar
    ) {
        for plan in plans {
            let cycle = PayCycle.containing(plan.cycleStart, payday: payday, calendar: calendar)
            // A plan for a cycle that has not started has nothing due yet — and that is
            // the common case, since the owner builds next cycle's plan before payday.
            guard cycle.start <= now else { continue }

            for item in plan.items ?? [] where item.autoCanFire && !item.isDone {
                guard let dueDay = item.dueDay,
                      let due = DueDay.date(day: dueDay, in: cycle, calendar: calendar),
                      due <= now else { continue }

                let expense = Expense(
                    // The *planned* figure — which is exactly the amount that may turn
                    // out to be wrong, and why needsReview exists.
                    amount: item.amount,
                    // 09:00 rather than midnight, so a posted expense sorts among the
                    // day's real ones instead of always leading them.
                    date: calendar.date(byAdding: .hour, value: 9, to: due) ?? due,
                    note: item.name,
                    category: item.category,
                    people: item.people ?? [],
                    account: item.account,
                    planItem: item,
                    needsReview: true
                )
                context.insert(expense)
            }
        }
    }

    // MARK: - Repair

    private static func foldTwinExpenses(in plans: [CyclePlan], context: ModelContext) {
        for plan in plans {
            for item in plan.items ?? [] {
                let linked = item.linkedExpenses ?? []
                guard linked.count > 1, let survivor = item.linkedExpense else { continue }
                for duplicate in linked where duplicate !== survivor {
                    // Narrow on purpose: only an unreviewed automatic write is folded.
                    // Anything the owner confirmed stays, even if that leaves two.
                    guard duplicate.needsReview else { continue }
                    context.delete(duplicate)
                }
            }
        }
    }

    private static func dedupePlans(_ plans: [CyclePlan], in context: ModelContext) {
        let byCycle = Dictionary(grouping: plans, by: \.cycleStart)
        for (_, group) in byCycle where group.count > 1 {
            guard let survivor = canonicalPlan(among: group) else { continue }
            for duplicate in group where duplicate !== survivor {
                for item in duplicate.items ?? [] { item.plan = survivor }
                for line in duplicate.incomeLines ?? [] { line.plan = survivor }
                for line in duplicate.transferLines ?? [] { line.plan = survivor }
                context.delete(duplicate)
            }
        }
    }

    /// The fuller plan wins, then the earlier one. The last tiebreak compares
    /// persistent IDs and is best-effort only — the same caveat `Person.canonicalMe`
    /// documents, and for the same reason: an ID is not stable until it is saved, and
    /// its string form is not a documented ordering. It only separates plans that are
    /// otherwise identical, and the next remote change re-runs this anyway.
    private static func canonicalPlan(among plans: [CyclePlan]) -> CyclePlan? {
        plans.min { a, b in
            let ca = (a.items?.count ?? 0) + (a.incomeLines?.count ?? 0)
            let cb = (b.items?.count ?? 0) + (b.incomeLines?.count ?? 0)
            if ca != cb { return ca > cb }
            return "\(a.persistentModelID)" < "\(b.persistentModelID)"
        }
    }
}
