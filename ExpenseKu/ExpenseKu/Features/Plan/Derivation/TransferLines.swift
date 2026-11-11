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
//  Each row also carries what its plate and caption draw — the Account's look, the count
//  and the due days — so the view never walks the items again (bank-logos.md §5.6.4),
//  and its members, so the line's sheet never does either (partial-transfer.md §6).
//
//  The Σ is derived per read, never stored, so adding or deleting an item can never
//  leave a stale total behind. So is how much of the line is in: it is read off the
//  members' states (§5.1). A TransferLine holds only the adjustment the owner sets,
//  and exists only once they have set one.
//

import Foundation
import SwiftData

nonisolated enum TransferLines {
    /// One row per account with money against it, largest first. An Envelope
    /// contributes through its optional Account like any Fixed item (PRD §7.6);
    /// dormant items are not in this cycle's plan and never contribute.
    static func rows(activeItems: [PlanItem], lines: [TransferLine],
                     paidEarly: PaidEarlyShift = .none, setAside: SetAsideShift = .none,
                     cycle: PayCycle? = nil, calendar: Calendar = .current) -> [TransferRow] {
        var planned: [PersistentIdentifier: Decimal] = [:]
        var credited: [PersistentIdentifier: Decimal] = [:]
        var creditedNames: [PersistentIdentifier: [String]] = [:]
        var setAsideIn: [PersistentIdentifier: Decimal] = [:]
        var setAsideNames: [PersistentIdentifier: [String]] = [:]
        var accounts: [PersistentIdentifier: Account] = [:]
        var members: [PersistentIdentifier: [PlanItem]] = [:]
        var transferMembers: [PersistentIdentifier: [TransferMember]] = [:]
        var allAuto: [PersistentIdentifier: Bool] = [:]

        for item in activeItems {
            guard let account = item.account else { continue }
            let id = account.persistentModelID
            let credit = paidEarly.credit(for: item)
            let saved = setAside.credit(for: item)
            let itemNet = net(item, paidEarly: credit, setAside: saved)
            planned[id, default: 0] += itemNet
            transferMembers[id, default: []].append(member(item, amount: itemNet, cycle: cycle, calendar: calendar))
            if credit > 0 {
                credited[id, default: 0] += credit
                creditedNames[id, default: []].append(item.name)
            }
            if saved > 0 {
                setAsideIn[id, default: 0] += saved
                setAsideNames[id, default: []].append(item.name)
            }
            accounts[id] = account
            members[id, default: []].append(item)
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
            let items = members[id] ?? []
            let account = accounts[id]
            let toGo = items.filter { PlanItemState.of($0) == .todo }
            return TransferRow(
                accountID: id,
                accountName: account?.name ?? "",
                planned: amount,
                adjustment: adjustments[id]?.adjustment ?? 0,
                allAuto: allAuto[id] ?? false,
                paidEarly: credited[id] ?? 0,
                paidEarlyEnvelopes: creditedNames[id] ?? [],
                setAside: setAsideIn[id] ?? 0,
                setAsideEnvelopes: setAsideNames[id] ?? [],
                plate: account.map(AccountPlateStyle.init(account:)),
                envelopeCount: items.count(where: \.isEnvelope),
                itemCount: items.count(where: { !$0.isEnvelope }),
                dueDays: dueDays(of: items, cycle: cycle, calendar: calendar),
                toGoDueDays: dueDays(of: toGo, cycle: cycle, calendar: calendar),
                members: (transferMembers[id] ?? []).sorted(by: TransferMember.precedes)
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

    static func member(_ item: PlanItem, amount: Decimal, cycle: PayCycle?, calendar: Calendar) -> TransferMember {
        TransferMember(
            id: item.persistentModelID,
            name: item.name,
            categoryName: item.category?.name,
            isAuto: item.isAuto,
            isEnvelope: item.isEnvelope,
            dueDay: item.dueDay,
            dueDate: item.dueDay.flatMap { day in cycle.flatMap { DueDay.date(day: day, in: $0, calendar: calendar) } },
            amount: amount,
            createdAt: item.createdAt,
            state: PlanItemState.of(item),
            check: DoneCheckState.state(for: item)
        )
    }

    /// Each day once, by where it falls in the cycle (plan-sort.md §4.1); without a
    /// cycle, or for a day the cycle cannot place, by its number after the placed ones.
    static func dueDays(of items: [PlanItem], cycle: PayCycle?, calendar: Calendar) -> [Int] {
        let days = Set(items.compactMap(\.dueDay))
        let placed = days.map { day in (day, cycle.flatMap { DueDay.date(day: day, in: $0, calendar: calendar) }) }
        return placed.sorted { a, b in
            switch (a.1, b.1) {
            case let (x?, y?) where x != y: x < y
            case (_?, nil): true
            case (nil, _?): false
            default: a.0 < b.0
            }
        }
        .map(\.0)
    }

    /// E3's "TRANSFER CHECKLIST · 2 OF 6 SENT": a line is sent once all of it is in;
    /// part in is not sent (partial-transfer.md §5.1).
    static func sentCount(_ rows: [TransferRow]) -> Int {
        rows.count(where: \.isAllIn)
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
    /// Every contributing item is Auto, so the row reads "keep this covered" rather
    /// than "send this". An Envelope is never Auto, so one on the line makes it "send".
    let allAuto: Bool
    /// The envelopes' capped paid-early credit already taken off `planned` (§4.10.10).
    var paidEarly: Decimal = 0
    var paidEarlyEnvelopes: [String] = []
    /// What earlier plans set aside for its envelopes, also off `planned` (set-aside.md §4.6).
    var setAside: Decimal = 0
    var setAsideEnvelopes: [String] = []
    /// How the line's plate draws its Account (bank-logos.md §5.6.1).
    var plate: AccountPlateStyle?
    var envelopeCount = 0
    var itemCount = 0
    /// In cycle order.
    var dueDays: [Int] = []
    /// The Todo members' due days, for a part-in caption.
    var toGoDueDays: [Int] = []
    /// In TO SEND's order (partial-transfer.md §6.2).
    var members: [TransferMember] = []

    var id: PersistentIdentifier { accountID }

    var fill: TransferFill { TransferFill.of(members) }
    var isAllIn: Bool { fill == .allIn }

    /// The adjustment counts in the first round only: once any member is in, it was
    /// moved with that round (§5.3).
    var isAdjustmentTaken: Bool { fill != .nothingIn }

    /// What is still to go: Σ of the Todo members.
    var toGo: Decimal {
        members.filter { !$0.isIn }.reduce(0) { $0 + $1.amount }
    }

    /// The line's figure: the whole transfer, or once part of it is in, what is still to
    /// go (§5.1). Never below zero, whatever the adjustment.
    var transfer: Decimal {
        fill == .partIn ? toGo : max(0, planned + adjustment)
    }
    var hasAdjustment: Bool { adjustment != 0 }

    /// VoiceOver's value for the line, and what `idb` reads back.
    var fillDescription: String {
        switch fill {
        case .nothingIn: AppLocalization.string(.noFundsIn)
        case .partIn: AppLocalization.string(.ofIn(String(members.count(where: \.isIn)), String(members.count)))
        case .allIn: AppLocalization.string(.allFundsIn)
        }
    }

    /// "Rp 1.200.000 paid early into Travelling"; several envelopes drop the name.
    var paidEarlyText: String? {
        guard paidEarly > 0 else { return nil }
        guard paidEarlyEnvelopes.count == 1, let name = paidEarlyEnvelopes.first else {
            return AppLocalization.string(.paidEarlyAmount(paidEarly.formattedIDR()))
        }
        return AppLocalization.string(.paidEarlyInto(paidEarly.formattedIDR(), name))
    }

    /// "Rp 12.000.000 set aside into Jepang"; several envelopes drop the name.
    var setAsideText: String? {
        guard setAside > 0 else { return nil }
        guard setAsideEnvelopes.count == 1, let name = setAsideEnvelopes.first else {
            return AppLocalization.string(.setAsideAmount(setAside.formattedIDR()))
        }
        return AppLocalization.string(.setAsideInto(setAside.formattedIDR(), name))
    }

    /// The line under the Account's name (bank-logos.md §5.6.4): "2 items · Due 12, 20",
    /// then the notes the line already carried. "Keep this covered" only speaks when
    /// nothing else does, as before. Part in, it names the round instead — "1 item in ·
    /// 2 to go" — and drops the adjustment, which that round took (partial-transfer.md §5.1).
    var caption: String {
        if fill == .partIn {
            let inCount = members.count(where: \.isIn)
            let round = PlanCopy.counted(inCount, .item) + AppLocalization.string(.inToGo(String(members.count - inCount)))
            return [round, PlanCopy.dueDays(toGoDueDays), creditText].compactMap(\.self)
                .joined(separator: " · ")
        }
        let count = PlanCopy.itemCount(items: itemCount, envelopes: envelopeCount)
        let adjustmentText = hasAdjustment ? AppLocalization.string(.adjustmentApplied(adjustment.formattedIDR())) : nil
        let notes = [adjustmentText, creditText].compactMap(\.self)
        let autoNote = notes.isEmpty && allAuto ? AppLocalization.string(.autoDebitKeepThisCovered) : nil
        return ([count, PlanCopy.dueDays(dueDays)] + notes + [autoNote]).compactMap(\.self)
            .joined(separator: " · ")
    }

    /// Why `planned` is less than the items add up to. Both credits together drop the
    /// names, so the line stays two lines at most: "Rp 6.500.000 paid early · Rp 12.000.000 set aside".
    var creditText: String? {
        guard paidEarly > 0, setAside > 0 else { return paidEarlyText ?? setAsideText }
        return AppLocalization.string(.paidEarlySetAside(paidEarly.formattedIDR(), setAside.formattedIDR()))
    }
}
