//
//  LookBackMark.swift
//  ExpenseKu
//
//  What one tap in the Look back sheet did to the plan on screen, kept while the sheet
//  is open so the row can say so and a second tap can take it back (look-back.md §6.5).
//  Nothing here can have an Expense yet, so undoing never touches the ledger.
//

import Foundation
import SwiftData

nonisolated enum LookBackMark {
    case copied(PlanItem)
    case woken(PlanItem)
    case newEnvelope(PlanItem)
    case newFixed(PlanItem)
    case addedCategory(Category, to: PlanItem)

    var label: String {
        if case .woken = self { return AppLocalization.string(.woken) }
        return AppLocalization.string(.added)
    }

    func caption(planMonth: String) -> String {
        switch self {
        case .copied: AppLocalization.string(.addedTo(planMonth))
        case .woken: AppLocalization.string(.wokenIn(planMonth))
        case .newEnvelope: AppLocalization.string(.newEnvelopeIn(planMonth))
        case .newFixed: AppLocalization.string(.newFixedItemIn(planMonth))
        case .addedCategory(_, let envelope): AppLocalization.string(.addedTo(envelope.name))
        }
    }
}
