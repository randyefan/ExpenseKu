//
//  PlanItemState.swift
//  ExpenseKu
//
//  Where a plan item's money is: not moved, in its Account, or paid (PRD §7.6).
//
//  Derived, so no combination of edits can contradict itself. Done comes from the
//  Expense link, exactly as before; Funded needs both the owner's flag and an Account
//  to be in. Clearing the Account therefore drops the item back to Todo without
//  touching the flag — and so does an older build that nils an Envelope's Account
//  when it saves one.
//

import Foundation

nonisolated enum PlanItemState: Equatable {
    case todo
    case funded
    case done

    /// A set-aside line is never Funded: moving its money is the whole act, so it goes
    /// straight from Todo to Done (set-aside.md §4.4).
    static func of(_ item: PlanItem) -> PlanItemState {
        if item.isSetAside { return item.isSetAsideMoved ? .done : .todo }
        if item.isDone { return .done }
        if item.isFunded, item.account != nil { return .funded }
        return .todo
    }
}
