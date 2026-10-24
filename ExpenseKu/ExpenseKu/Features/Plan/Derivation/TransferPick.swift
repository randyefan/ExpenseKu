//
//  TransferPick.swift
//  ExpenseKu
//
//  What one transfer line's sheet shows for a choice of its items
//  (docs/prd/partial-transfer.md §6): the items still to send, the ones already in,
//  and the figure to type into the banking app.
//
//  With only one income in, the owner moves some of a line's items now and the rest
//  when the next income lands. The choice is the sheet's own state and dies with it
//  (§7); only recording it — the items becoming Funded — outlives the sheet.
//

import Foundation
import SwiftData

nonisolated struct TransferPick {
    let row: TransferRow
    let chosen: Set<PersistentIdentifier>

    /// The sheet opens with every Todo item chosen (decision 5), so a payday with all
    /// the income in is still two taps.
    static func initialChoice(for row: TransferRow) -> Set<PersistentIdentifier> {
        Set(row.members.filter { !$0.isIn }.map(\.id))
    }

    var toSend: [TransferMember] { row.members.filter { !$0.isIn } }
    var alreadyIn: [TransferMember] { row.members.filter(\.isIn) }

    var chosenMembers: [TransferMember] { toSend.filter { chosen.contains($0.id) } }

    func isChosen(_ member: TransferMember) -> Bool { chosen.contains(member.id) }

    /// Σ chosen, plus the adjustment while this is still the first round (§5.3).
    /// Nothing chosen moves nothing, adjustment or not.
    var transferNow: Decimal {
        let picked = chosenMembers
        guard !picked.isEmpty else { return 0 }
        let adjustment = row.isAdjustmentTaken ? 0 : row.adjustment
        return max(0, picked.reduce(0) { $0 + $1.amount } + adjustment)
    }

    var canRecord: Bool { !chosenMembers.isEmpty }

    /// "Covered in BNI" when every chosen item is Auto — the Auto menu's words (§7.6) —
    /// else "Moved to BCA".
    var recordEntry: FundMenuEntry {
        let picked = chosenMembers
        let allAuto = !picked.isEmpty && picked.allSatisfy(\.isAuto)
        return allAuto ? .covered(account: row.accountName) : .moved(account: row.accountName)
    }

    var sendTitle: String { "To send · \(chosenMembers.count) of \(toSend.count)" }
    var alreadyInTitle: String { "Already in \(row.accountName)" }
    var allInMessage: String { "Everything for \(row.accountName) is in." }

    /// Once all of it is in there is nothing to send now; the figure is the line's total.
    var figureTitle: String { toSend.isEmpty ? "Total" : "Transfer now" }
    var figure: Decimal { toSend.isEmpty ? row.transfer : transferNow }

    var adjustmentNote: String? {
        row.hasAdjustment && row.isAdjustmentTaken ? "Taken with the first transfer" : nil
    }
}
