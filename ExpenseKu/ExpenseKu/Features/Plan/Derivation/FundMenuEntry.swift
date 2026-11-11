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
    /// A set-aside line's one item (set-aside.md §4.4): "Moved to Jago", or "Set aside"
    /// with no Account.
    case setAsideMoved(account: String?, target: String?)
    case setAsideUndo(hasAccount: Bool)

    /// The value `isFunded` takes, or nil for "Paid…", which sets nothing itself.
    var fundedValue: Bool? {
        switch self {
        case .moved, .covered: true
        case .notMoved, .notCovered: false
        case .paid, .setAsideMoved, .setAsideUndo: nil
        }
    }

    /// The value `isSetAsideMoved` takes, or nil for every Funded entry.
    var setAsideMovedValue: Bool? {
        switch self {
        case .setAsideMoved: true
        case .setAsideUndo: false
        default: nil
        }
    }

    var title: String {
        switch self {
        case .moved(let account): AppLocalization.string(.movedTo(account))
        case .covered(let account): AppLocalization.string(.coveredIn(account))
        case .notMoved: AppLocalization.string(.notMovedYet)
        case .notCovered: AppLocalization.string(.notCoveredYet)
        case .paid: AppLocalization.string(.paid)
        case .setAsideMoved(let account, _): account.map { AppLocalization.string(.movedTo($0)) } ?? AppLocalization.string(.setAside)
        case .setAsideUndo(let hasAccount): hasAccount ? AppLocalization.string(.notMovedYet) : AppLocalization.string(.notSetAsideYet)
        }
    }

    var subtitle: String {
        switch self {
        case .moved: AppLocalization.string(.moneyIsInTheAccount)
        case .covered: AppLocalization.string(.enoughIsThereForTheDebit)
        case .notMoved, .notCovered: AppLocalization.string(.backToTodo)
        case .paid: AppLocalization.string(.logTheExpenseNow)
        case .setAsideMoved(_, let target): target.map { AppLocalization.string(.setAsideFor($0)) } ?? AppLocalization.string(.noEnvelopeYet)
        case .setAsideUndo: AppLocalization.string(.backToTodo)
        }
    }

    var systemImage: String {
        switch self {
        case .moved, .covered: "arrow.down.to.line"
        case .notMoved, .notCovered: "arrow.uturn.backward"
        case .paid, .setAsideMoved: "checkmark.circle"
        case .setAsideUndo: "arrow.uturn.backward"
        }
    }
}
