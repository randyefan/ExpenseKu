//
//  PlanAction.swift
//  ExpenseKu
//
//  Everything the Plan lens can ask for, raised to ExpensesView rather than handled
//  in place.
//
//  The lens sits under `.id(LensKey(cycle:lens:))`, so it is torn down and rebuilt on
//  every page and every lens switch. Anything it owned — a presented sheet, an
//  expanded section — would vanish mid-interaction. So it owns no state and performs
//  no writes: it reports, and the view above the `.id()` decides.
//

import Foundation

enum PlanAction {
    case startPlan

    case addIncomeLine
    case editIncomeLine(IncomeLine)
    case toggleIncomeArrived(IncomeLine)

    case addPlanItem
    case editPlanItem(PlanItem)
    /// The owner tapped a row's Done control. What that means depends on the row's
    /// state, which is `DoneCheckState`'s job, not the lens's.
    case tapDoneCheck(PlanItem)
    case activateDormant(PlanItem)
    case toggleDormantSection

    case toggleTransferred(TransferRow)
    case editAdjustment(TransferRow)

    case openReview
}
