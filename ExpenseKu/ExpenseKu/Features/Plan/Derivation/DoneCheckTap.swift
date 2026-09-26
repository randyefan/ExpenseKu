//
//  DoneCheckTap.swift
//  ExpenseKu
//
//  What tapping a row's lead control does (PRD §7.6's table, frames L2–L4 and L7).
//
//  Every change of Funded goes through a Menu, never a bare toggle, so a stray tap
//  while scrolling changes nothing — including the one-item menus on the Auto bolt and
//  the Envelope tray. An item with no Account has nowhere to be Funded and keeps what
//  it did before §7.6: ◯ opens the Done sheet directly, the bolt and tray are inert.
//

import Foundation

nonisolated enum DoneCheckTap: Equatable {
    /// Nothing to do: an Auto item that has not fired, or an Envelope, with no Account.
    case none
    /// E4, straight away.
    case confirmDone
    /// I4: un-ticking deletes the Expense the tick created.
    case untick
    case menu([FundMenuEntry])

    static func of(_ item: PlanItem) -> DoneCheckTap {
        let state = DoneCheckState.state(for: item)
        guard let account = item.account?.name else {
            switch state {
            case .done, .autoPosted: return .untick
            case .todo, .funded: return .confirmDone
            case .auto, .autoFunded, .envelope, .envelopeFunded: return .none
            }
        }
        switch state {
        case .done, .autoPosted: return .untick
        case .todo: return .menu([.moved(account: account), .paid])
        case .funded: return .menu([.paid, .notMoved])
        case .auto: return .menu([.covered(account: account)])
        case .autoFunded: return .menu([.notCovered])
        case .envelope: return .menu([.moved(account: account)])
        case .envelopeFunded: return .menu([.notMoved])
        }
    }
}
