//
//  LookBackPlanRow.swift
//  ExpenseKu
//
//  A plan item of the reviewed cycle that the plan on screen lacks (look-back.md §5.1).
//

import Foundation
import SwiftData

nonisolated struct LookBackPlanRow: Identifiable {
    enum Action {
        case add
        /// The plan on screen has this item, dormant. Waking it gives it `source`'s amount.
        case wake(PlanItem)
    }

    let source: PlanItem
    let action: Action
    /// Rp 0 and never done in the reviewed cycle: listed, dimmed, last.
    let isUnused: Bool
    let amountLine: String
    let caption: String?

    var id: LookBackRowID { .item(source.persistentModelID) }
}
