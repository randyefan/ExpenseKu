//
//  PlanContents.swift
//  ExpenseKu
//
//  Everything the Plan lens derives from one cycle's plan: the rows, the totals, the
//  rollups and the review state. Computed once per body pass rather than re-derived
//  by each of the header, the totals card, the item list and the two rollup sections,
//  and pure so it can be unit-tested without a ModelContainer.
//
//  This is CycleContents' opposite number, and deliberately the same shape — the two
//  are one cycle seen from either side. It takes the *same* filtered expense array
//  CycleContents holds, so the plan and the ledger can never disagree about what fell
//  in this cycle.
//

import Foundation
import SwiftData

nonisolated struct PlanContents {
    let plan: CyclePlan?
    let cycle: PayCycle

    let incomeLines: [IncomeLine]
    let activeItems: [PlanItem]
    let dormantItems: [PlanItem]

    let totals: PlanTotals
    let transfers: [TransferRow]
    let groupShares: [GroupShare]
    let review: ReviewState

    private let envelopesByItem: [PersistentIdentifier: EnvelopeProgress]

    init(plan: CyclePlan?, cycle: PayCycle, cycleExpenses: [Expense]) {
        self.plan = plan
        self.cycle = cycle

        incomeLines = (plan?.incomeLines ?? []).sorted { $0.createdAt < $1.createdAt }
        let split = PlanDormancy.split(plan?.items ?? [])
        activeItems = split.active
        dormantItems = split.dormant

        let envelopes = EnvelopeSpend.progress(
            envelopes: split.active.filter(\.isEnvelope),
            cycleExpenses: cycleExpenses
        )
        envelopesByItem = Dictionary(uniqueKeysWithValues: envelopes.map { ($0.itemID, $0) })

        totals = PlanTotals(activeItems: split.active, incomeLines: incomeLines, envelopes: envelopes)
        transfers = TransferLines.rows(activeItems: split.active, lines: plan?.transferLines ?? [])
        groupShares = GroupShares.rows(activeItems: split.active, totalIncome: totals.totalIncome)
        review = ReviewState(cycleItems: split.active)
    }

    /// No plan exists for this cycle at all — only reachable for the first one, since
    /// every later cycle is copied forward (§7.2). Frame I5.
    var hasPlan: Bool { plan != nil }

    /// A plan exists but holds nothing yet, which is what the owner sees in the moment
    /// after tapping "Start this cycle's plan".
    var isEmpty: Bool { activeItems.isEmpty && dormantItems.isEmpty && incomeLines.isEmpty }

    var doneCount: Int { activeItems.count(where: \.isDone) }
    var sectionTitle: String {
        PlanCopy.sectionTitle(itemCount: activeItems.count, doneCount: doneCount)
    }
    var headline: CycleHeadline { .sisa(totals.sisa) }

    func envelope(for item: PlanItem) -> EnvelopeProgress? {
        envelopesByItem[item.persistentModelID]
    }
}
