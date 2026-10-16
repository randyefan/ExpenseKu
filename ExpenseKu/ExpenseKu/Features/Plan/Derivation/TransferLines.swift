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
    /// One row per account with money against it, largest first. An Envelope
    /// contributes through its optional Account like any Fixed item (PRD §7.6);
    /// dormant items are not in this cycle's plan and never contribute.
    static func rows(activeItems: [PlanItem], lines: [TransferLine],
                     paidEarly: PaidEarlyShift = .none, setAside: SetAsideShift = .none) -> [TransferRow] {
        var planned: [PersistentIdentifier: Decimal] = [:]
        var credited: [PersistentIdentifier: Decimal] = [:]
        var creditedNames: [PersistentIdentifier: [String]] = [:]
        var setAsideIn: [PersistentIdentifier: Decimal] = [:]
        var setAsideNames: [PersistentIdentifier: [String]] = [:]
        var names: [PersistentIdentifier: String] = [:]
        var allAuto: [PersistentIdentifier: Bool] = [:]

        for item in activeItems {
            guard let account = item.account else { continue }
            let id = account.persistentModelID
            let credit = paidEarly.credit(for: item)
            let saved = setAside.credit(for: item)
            planned[id, default: 0] += net(item, paidEarly: credit, setAside: saved)
            if credit > 0 {
                credited[id, default: 0] += credit
                creditedNames[id, default: []].append(item.name)
            }
            if saved > 0 {
                setAsideIn[id, default: 0] += saved
                setAsideNames[id, default: []].append(item.name)
            }
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
                allAuto: allAuto[id] ?? false,
                paidEarly: credited[id] ?? 0,
                paidEarlyEnvelopes: creditedNames[id] ?? [],
                setAside: setAsideIn[id] ?? 0,
                setAsideEnvelopes: setAsideNames[id] ?? []
            )
        }
        .sorted { a, b in
            if a.planned != b.planned { return a.planned > b.planned }
            return a.accountName < b.accountName
        }
    }

    /// An envelope's contribution net of what earlier cycles already covered, never below
    /// zero (set-aside.md §4.6): set aside uncapped, it can exceed the plan.
    static func net(_ item: PlanItem, paidEarly: Decimal, setAside: Decimal) -> Decimal {
        guard paidEarly + setAside > 0 else { return item.amount }
        return max(0, item.amount - paidEarly - setAside)
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
    /// than "send this". An Envelope is never Auto, so one on the line makes it "send".
    let allAuto: Bool
    /// The envelopes' capped paid-early credit already taken off `planned` (§4.10.10).
    var paidEarly: Decimal = 0
    var paidEarlyEnvelopes: [String] = []
    /// What earlier plans set aside for its envelopes, also off `planned` (set-aside.md §4.6).
    var setAside: Decimal = 0
    var setAsideEnvelopes: [String] = []

    var id: PersistentIdentifier { accountID }

    /// What the owner actually moves.
    var transfer: Decimal { planned + adjustment }
    var hasAdjustment: Bool { adjustment != 0 }

    /// "Rp 1.200.000 paid early into Travelling"; several envelopes drop the name.
    var paidEarlyText: String? {
        guard paidEarly > 0 else { return nil }
        guard paidEarlyEnvelopes.count == 1, let name = paidEarlyEnvelopes.first else {
            return "\(paidEarly.formattedIDR()) paid early"
        }
        return "\(paidEarly.formattedIDR()) paid early into \(name)"
    }

    /// "Rp 12.000.000 set aside into Jepang"; several envelopes drop the name.
    var setAsideText: String? {
        guard setAside > 0 else { return nil }
        guard setAsideEnvelopes.count == 1, let name = setAsideEnvelopes.first else {
            return "\(setAside.formattedIDR()) set aside"
        }
        return "\(setAside.formattedIDR()) set aside into \(name)"
    }

    /// Why `planned` is less than the items add up to. Both credits together drop the
    /// names, so the line stays two lines at most: "Rp 6.500.000 paid early · Rp 12.000.000 set aside".
    var creditText: String? {
        guard paidEarly > 0, setAside > 0 else { return paidEarlyText ?? setAsideText }
        return "\(paidEarly.formattedIDR()) paid early · \(setAside.formattedIDR()) set aside"
    }
}
