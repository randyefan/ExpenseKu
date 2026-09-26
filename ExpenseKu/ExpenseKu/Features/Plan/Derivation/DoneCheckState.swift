//
//  DoneCheckState.swift
//  ExpenseKu
//
//  The faces of the control that leads a plan row (`DoneCheck` in the design system).
//  Derived in one place rather than read as a handful of booleans at the view, so a
//  row can never render two of them at once.
//
//  The control leads where a category icon would on an ExpenseRow, deliberately: a
//  plan is a checklist and must not look like the ledger (PRD §6.2).
//

import Foundation

nonisolated enum DoneCheckState: Equatable {
    /// A Fixed item waiting to be ticked.
    case todo
    /// A Fixed item whose money is in its Account, not yet paid (§7.6).
    case funded
    /// Ticked by hand, with a linked Expense carrying the actual amount.
    case done
    /// Auto, with a due day that has not arrived. The owner never acts on it.
    case auto
    /// Auto, and its Account already covers the debit. It still posts itself.
    case autoFunded
    /// Auto, and its Expense has been written without confirmation — so it carries a
    /// Review chip until the owner clears the flag (ADR-0007).
    case autoPosted
    /// An Envelope, which is never ticked at all: it has no transaction to complete,
    /// and fills itself from expenses already logged.
    case envelope
    /// An Envelope whose allowance is in its Account — its last state.
    case envelopeFunded

    static func state(for item: PlanItem) -> DoneCheckState {
        let state = PlanItemState.of(item)
        if item.isEnvelope { return state == .funded ? .envelopeFunded : .envelope }
        if item.isAuto {
            switch state {
            case .done: return .autoPosted
            case .funded: return .autoFunded
            case .todo: return .auto
            }
        }
        switch state {
        case .done: return .done
        case .funded: return .funded
        case .todo: return .todo
        }
    }
}
