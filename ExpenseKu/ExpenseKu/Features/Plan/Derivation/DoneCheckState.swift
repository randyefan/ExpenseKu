//
//  DoneCheckState.swift
//  ExpenseKu
//
//  The five faces of the control that leads a plan row (`DoneCheck` in the design
//  system). Derived in one place rather than read as five booleans at the view, so a
//  row can never render two of them at once.
//
//  The control leads where a category icon would on an ExpenseRow, deliberately: a
//  plan is a checklist and must not look like the ledger (PRD §6.2).
//

import Foundation

nonisolated enum DoneCheckState: Equatable {
    /// A Fixed item waiting to be ticked. Tapping opens the confirmation sheet.
    case todo
    /// Ticked by hand, with a linked Expense carrying the actual amount.
    case done
    /// Auto, with a due day that has not arrived. The owner never acts on it.
    case auto
    /// Auto, and its Expense has been written without confirmation — so it carries a
    /// Review chip until the owner clears the flag (ADR-0007).
    case autoPosted
    /// An Envelope, which is never ticked at all: it has no transaction to complete,
    /// and fills itself from expenses already logged.
    case envelope

    static func state(for item: PlanItem) -> DoneCheckState {
        if item.isEnvelope { return .envelope }
        if item.isDone {
            return item.isAuto ? .autoPosted : .done
        }
        return item.isAuto ? .auto : .todo
    }

    /// Whether tapping this control does anything. An envelope's is inert, and an
    /// Auto item that has not fired has nothing to confirm yet.
    var isActionable: Bool {
        switch self {
        case .todo, .done, .autoPosted: true
        case .auto, .envelope: false
        }
    }
}
