//
//  FundMenuEntry.swift
//  ExpenseKu
//
//  The lines of a Funded menu (PRD §7.6, L2–L4), with their copy, so the words a
//  button promises are tested rather than typed inline in a view.
//

import Foundation

/// One line of a Funded menu, with the second line iOS shows beneath the title.
nonisolated enum FundMenuEntry: Hashable {
    case moved(account: String)
    case covered(account: String)
    case notMoved
    case notCovered
    /// Opens E4, which is what actually makes the item Done.
    case paid

    /// The value `isFunded` takes, or nil for "Paid…", which sets nothing itself.
    var fundedValue: Bool? {
        switch self {
        case .moved, .covered: true
        case .notMoved, .notCovered: false
        case .paid: nil
        }
    }

    var title: String {
        switch self {
        case .moved(let account): "Moved to \(account)"
        case .covered(let account): "Covered in \(account)"
        case .notMoved: "Not moved yet"
        case .notCovered: "Not covered yet"
        case .paid: "Paid…"
        }
    }

    var subtitle: String {
        switch self {
        case .moved: "Money is in the account"
        case .covered: "Enough is there for the debit"
        case .notMoved, .notCovered: "Back to Todo"
        case .paid: "Log the expense now"
        }
    }

    var systemImage: String {
        switch self {
        case .moved, .covered: "arrow.down.to.line"
        case .notMoved, .notCovered: "arrow.uturn.backward"
        case .paid: "checkmark.circle"
        }
    }
}
