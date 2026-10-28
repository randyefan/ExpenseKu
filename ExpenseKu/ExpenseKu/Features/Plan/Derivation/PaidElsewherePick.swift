//
//  PaidElsewherePick.swift
//  ExpenseKu
//
//  What one Account's Move from Jago sheet shows for a choice of its expenses
//  (docs/prd/paid-elsewhere.md §4.5): the ones still to move, the ones already moved,
//  and the figure to type into the banking app.
//
//  A card statement can close mid-trip, so the owner moves the Grabs on this month's bill
//  now and the rest next month. The choice is the sheet's own state and dies with it;
//  only recording it — the expenses' marks — outlives the sheet.
//

import Foundation
import SwiftData

nonisolated struct PaidElsewherePick {
    let row: PaidElsewhereRow
    let chosen: Set<PersistentIdentifier>

    /// The sheet opens with every expense not yet moved chosen.
    static func initialChoice(for row: PaidElsewhereRow) -> Set<PersistentIdentifier> {
        Set(row.members.filter { !$0.isMoved }.map(\.id))
    }

    var toMove: [PaidElsewhereMember] { row.members.filter { !$0.isMoved } }
    var alreadyMoved: [PaidElsewhereMember] { row.members.filter(\.isMoved) }

    var chosenMembers: [PaidElsewhereMember] { toMove.filter { chosen.contains($0.id) } }

    func isChosen(_ member: PaidElsewhereMember) -> Bool { chosen.contains(member.id) }

    var canRecord: Bool { !chosenMembers.isEmpty }

    var moveNow: Decimal { chosenMembers.reduce(0) { $0 + $1.amount } }

    var title: String { "Move from \(row.homeName)" }
    var subtitle: String { "to \(row.accountName)" }
    var recordTitle: String { "Moved from \(row.homeName)" }
    var toMoveTitle: String { "To move · \(chosenMembers.count) of \(toMove.count)" }
    var alreadyMovedTitle: String { "Already moved" }
    var allMovedMessage: String { "Everything on \(row.accountName) is moved." }

    /// With everything moved there is nothing to move now; the figure is the row's total.
    var figureTitle: String { toMove.isEmpty ? "Total" : "Move now" }
    var figure: Decimal { toMove.isEmpty ? row.total : moveNow }
}
