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
    /// A tap on an active Envelope row's body (envelope-detail.md §4.1).
    case openEnvelope(PlanItem)
    /// ＋ on an envelope row: Add Expense, already assigned there (envelope-assignment.md §4.5).
    case addExpense(to: PlanItem)
    /// "Move expenses here…" from the same menu (envelope-assignment.md §4.9).
    case moveExpenses(to: PlanItem)
    /// The owner tapped a row's Done control. What that means depends on the row's
    /// state, which is `DoneCheckState`'s job, not the lens's.
    case tapDoneCheck(PlanItem)
    /// A line of a Funded menu (§7.6): set or clear Funded, or "Paid…" into E4.
    case chooseFunding(PlanItem, FundMenuEntry)
    case activateDormant(PlanItem)
    case toggleDormantSection

    /// A transfer line: its sheet, to move some or all of its items (partial-transfer.md §5.2).
    case openTransfer(TransferRow)

    case openReview
    /// The plan's foot: Look back at the cycle before (look-back.md §4).
    case lookBack
    /// L6: narrow the plan to its Funded Fixed items, or widen it back.
    case showFunded
    case clearFundedFilter
    case sortPlan(PlanSort)
}
