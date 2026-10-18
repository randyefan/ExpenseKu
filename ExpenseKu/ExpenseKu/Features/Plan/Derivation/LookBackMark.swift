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
        if case .woken = self { return "Woken" }
        return "Added"
    }

    func caption(planMonth: String) -> String {
        switch self {
        case .copied: "added to \(planMonth)"
        case .woken: "woken in \(planMonth)"
        case .newEnvelope: "new envelope in \(planMonth)"
        case .newFixed: "new fixed item in \(planMonth)"
        case .addedCategory(_, let envelope): "added to \(envelope.name)"
        }
    }
}
