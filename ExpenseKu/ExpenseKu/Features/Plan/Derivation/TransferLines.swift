//
//  TransferLines.swift
//  ExpenseKu
//
//  The payday checklist: one row per Account the plan owes money from, each with the
//  derived total, the owner's manual adjustment, and whether they have made the
//  transfer (PRD §6.1.4, §7.5).
//
//  The owner works down this with six banking apps open, so the row has to say the
//  amount and nothing else.
//
//  Two rules verified against all nine cycles of the spreadsheet and worth stating,
//  because both look like they should be special cases and are not:
//
//  An Auto item still contributes. `ke BNI Rp 7.706.000` is `Cicilan Rumah BNI`, an
//  Auto row. The line does not mean "transfer this" — it means "make sure this
//  account holds enough for the debit to clear" (ADR-0007).
//
//  Credit cards are summed exactly like every other account (`ke CC Danamon` = Σ of
//  its rows, every cycle). There are no account types (§4).
//
//  The Σ is derived per read, never stored, so adding or deleting an item can never
//  leave a stale total behind. A TransferLine holds only the two facts the owner
//  sets, and exists only once they have set one.
//

import Foundation
import SwiftData

nonisolated enum TransferLines {
    /// One row per account with money against it, largest first. Envelopes have no
    /// account and never contribute; dormant items are not in this cycle's plan and
    /// never contribute.
    static func rows(activeItems: [PlanItem], lines: [TransferLine]) -> [TransferRow] {
        var planned: [PersistentIdentifier: Decimal] = [:]
        var names: [PersistentIdentifier: String] = [:]
        var allAuto: [PersistentIdentifier: Bool] = [:]

        for item in activeItems where item.kind == .fixed {
            guard let account = item.account else { continue }
            let id = account.persistentModelID
            planned[id, default: 0] += item.amount
            names[id] = account.name
            allAuto[id] = (allAuto[id] ?? true) && item.isAuto
        }

        let adjustments = Dictionary(
            lines.compactMap { line -> (PersistentIdentifier, TransferLine)? in
                guard let account = line.account else { return nil }
                return (account.persistentModelID, line)
            },
            uniquingKeysWith: { first, _ in first }
        )

        return planned.map { id, amount in
            TransferRow(
                accountID: id,
                accountName: names[id] ?? "",
                planned: amount,
                adjustment: adjustments[id]?.adjustment ?? 0,
                hasTransferred: adjustments[id]?.hasTransferred ?? false,
                allAuto: allAuto[id] ?? false
            )
        }
        .sorted { a, b in
            if a.planned != b.planned { return a.planned > b.planned }
            return a.accountName < b.accountName
        }
    }

    /// E3's "TRANSFER CHECKLIST · 2 OF 6 SENT".
    static func sentCount(_ rows: [TransferRow]) -> Int {
        rows.count(where: \.hasTransferred)
    }
}

nonisolated struct TransferRow: Identifiable, Equatable {
    let accountID: PersistentIdentifier
    let accountName: String
    /// Σ of the plan's items paid from this account.
    let planned: Decimal
    /// Signed. Negative means "transfer less than the plan says" — money already
    /// sitting in the account.
    let adjustment: Decimal
    let hasTransferred: Bool
    /// Every contributing item is Auto, so the row reads "keep this covered" rather
    /// than "send this".
    let allAuto: Bool

    var id: PersistentIdentifier { accountID }

    /// What the owner actually moves.
    var transfer: Decimal { planned + adjustment }
    var hasAdjustment: Bool { adjustment != 0 }
}
