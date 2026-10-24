//
//  PartialTransferTests.swift
//  ExpenseKuTests
//
//  Transferring part of a line (docs/prd/partial-transfer.md), one test per rule, on the
//  PRD's own sample (§4): the Plan lens's normal seed, payday 25, so the cycle runs
//  25 Oct → 24 Nov 2026. Gaji Fulltime is in, Tunjangan is not.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PartialTransferTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private var cycle: PayCycle {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)) ?? .distantPast
        return PayCycle.containing(day, payday: 25, calendar: calendar)
    }

    private struct Sample {
        let plan: CyclePlan
        let items: [String: PlanItem]
        let lines: [TransferLine]
        var active: [PlanItem] { Array(items.values) }
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        var accounts: [String: Account] = [:]
        for name in ["BNI", "CC Danamon", "BCA", "Mandiri", "Cash"] {
            let account = Account(name: name)
            context.insert(account)
            accounts[name] = account
        }
        var categories: [String: ExpenseKu.Category] = [:]
        for name in ["Cicilan", "Hiburan", "Sewa", "Kesehatan", "Utilitas", "Transfer", "Tagihan", "Parkir"] {
            let category = ExpenseKu.Category(name: name)
            context.insert(category)
            categories[name] = category
        }
        let spec: [(String, Decimal, String, String, Int?, Bool)] = [
            ("Cicilan Rumah BNI", 7_706_000, "Cicilan", "BNI", 20, true),
            ("Cicil ke Kartu Kredit", 4_700_000, "Cicilan", "CC Danamon", 25, true),
            ("Netflix", 130_000, "Hiburan", "CC Danamon", 2, true),
            ("Apple Service", 59_000, "Hiburan", "CC Danamon", 18, true),
            ("Vidio", 49_000, "Hiburan", "CC Danamon", 18, true),
            ("Kos", 2_200_000, "Sewa", "BCA", 5, false),
            ("Gym membership", 300_000, "Kesehatan", "BCA", 1, true),
            ("Listrik Kos", 247_300, "Utilitas", "BCA", nil, false),
            ("Tarisa Needs", 1_500_000, "Transfer", "Mandiri", nil, false),
            ("Kirim buat Ibu", 1_000_000, "Transfer", "Mandiri", nil, false),
            ("Tagihan Handphone Ibu", 326_500, "Tagihan", "Mandiri", nil, false),
            ("Bayar parkir motor SQ", 650_000, "Parkir", "Cash", nil, false),
        ]
        var items: [String: PlanItem] = [:]
        for (offset, (name, amount, category, account, dueDay, isAuto)) in spec.enumerated() {
            let item = PlanItem(name: name, amount: amount, dueDay: dueDay, isAuto: isAuto,
                                createdAt: Date(timeIntervalSince1970: Double(offset)), plan: plan,
                                category: categories[category], account: accounts[account])
            context.insert(item)
            items[name] = item
        }
        let paid = try XCTUnwrap(items["Tagihan Handphone Ibu"])
        context.insert(Expense(amount: 373_800, planItem: paid))
        paid.recordPaid()

        let lines = [TransferLine(account: accounts["BNI"], hasTransferred: true, plan: plan),
                     TransferLine(account: accounts["CC Danamon"], hasTransferred: true, plan: plan),
                     TransferLine(account: accounts["Mandiri"], adjustment: -700_000, plan: plan)]
        lines.forEach(context.insert)
        try context.save()
        return Sample(plan: plan, items: items, lines: lines)
    }

    private func rows(_ s: Sample) -> [TransferRow] {
        TransferLines.rows(activeItems: s.active, lines: s.lines, cycle: cycle, calendar: calendar)
    }

    private func row(_ name: String, _ s: Sample) throws -> TransferRow {
        try XCTUnwrap(rows(s).first { $0.accountName == name })
    }

    private func names(_ members: [TransferMember]) -> [String] { members.map(\.name) }

    // MARK: - §8 Existing data

    /// A line stored as Sent sets its Todo items Funded once, then clears the flag, so
    /// BNI and CC Danamon read all in as they did (AD1).
    @MainActor
    func testAStoredSentTickBecomesFundedItemsOnce() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        PlanMaintenance.convertSentTicks(in: [s.plan])

        XCTAssertEqual(PlanItemState.of(try XCTUnwrap(s.items["Cicilan Rumah BNI"])), .funded)
        XCTAssertEqual(PlanItemState.of(try XCTUnwrap(s.items["Netflix"])), .funded)
        XCTAssertEqual(PlanItemState.of(try XCTUnwrap(s.items["Kos"])), .todo, "BCA was never ticked")
        XCTAssertTrue(s.lines.allSatisfy { !$0.hasTransferred })
        XCTAssertTrue(try row("BNI", s).isAllIn)
        XCTAssertTrue(try row("CC Danamon", s).isAllIn)

        s.items["Netflix"]?.isFunded = false
        PlanMaintenance.convertSentTicks(in: [s.plan])
        XCTAssertEqual(PlanItemState.of(try XCTUnwrap(s.items["Netflix"])), .todo, "it runs once")
    }

    /// The conversion leaves a Done item Done and a dormant item alone.
    @MainActor
    func testTheConversionTouchesOnlyActiveTodoItems() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI")
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(bni)
        context.insert(plan)
        let posted = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, plan: plan, account: bni)
        let dormant = PlanItem(name: "Qurban", amount: 0, carriedOver: true, plan: plan, account: bni)
        [posted, dormant].forEach(context.insert)
        context.insert(Expense(amount: 7_706_000, planItem: posted))
        context.insert(TransferLine(account: bni, hasTransferred: true, plan: plan))
        try context.save()

        PlanMaintenance.convertSentTicks(in: [plan])

        XCTAssertEqual(PlanItemState.of(posted), .done)
        XCTAssertFalse(dormant.isFunded)
    }

    // MARK: - §5.1 The line

    @MainActor
    func testTheLineReadsNothingInPartInAndAllInOffItsItems() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        PlanMaintenance.convertSentTicks(in: [s.plan])

        XCTAssertEqual(try row("BCA", s).fill, .nothingIn)
        XCTAssertEqual(try row("Mandiri", s).fill, .partIn, "a Done item is in")
        XCTAssertEqual(try row("BNI", s).fill, .allIn)
        XCTAssertEqual(try row("BCA", s).fillDescription, "Nothing in yet")
        XCTAssertEqual(try row("Mandiri", s).fillDescription, "1 of 3 in")
    }

    /// Nothing in: Σ + adjustment, never below zero; the caption is unchanged.
    @MainActor
    func testNothingInShowsTheWholeTransferNeverBelowZero() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertEqual(try row("BCA", s).transfer, 2_747_300)
        XCTAssertEqual(try row("BCA", s).caption, "3 items · Due 1, 5")

        let superbank = Account(name: "Superbank")
        context.insert(superbank)
        let item = PlanItem(name: "Tabungan", amount: 500_000, account: superbank)
        context.insert(item)
        let line = TransferLine(account: superbank, adjustment: -700_000)
        context.insert(line)
        let clamped = try XCTUnwrap(TransferLines.rows(activeItems: [item], lines: [line]).first)
        XCTAssertEqual(clamped.transfer, 0)
    }

    /// Part in: the Todo items' total, "1 item in · 2 to go" and their due days only (AD4).
    @MainActor
    func testPartInShowsWhatIsStillToGo() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.items["Kos"]?.recordMoved()

        let bca = try row("BCA", s)
        XCTAssertEqual(bca.fill, .partIn)
        XCTAssertEqual(bca.transfer, 547_300)
        XCTAssertEqual(bca.caption, "1 item in · 2 to go · Due 1")
    }

    /// §5.3: the adjustment counts in the first round only. Tagihan Handphone Ibu is
    /// paid, so Mandiri's −700.000 is taken and the line is its Todo items alone.
    @MainActor
    func testTheAdjustmentIsTakenOnceAnyItemIsIn() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        let mandiri = try row("Mandiri", s)
        XCTAssertTrue(mandiri.isAdjustmentTaken)
        XCTAssertEqual(mandiri.transfer, 2_500_000)
        XCTAssertEqual(mandiri.caption, "1 item in · 2 to go")

        let pick = TransferPick(row: mandiri, chosen: TransferPick.initialChoice(for: mandiri))
        XCTAssertEqual(pick.transferNow, 2_500_000)
        XCTAssertEqual(pick.adjustmentNote, "Taken with the first transfer")
    }

    /// The header counts all-in lines; a part-in line is not sent.
    @MainActor
    func testTheHeaderCountsOnlyAllInLines() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        PlanMaintenance.convertSentTicks(in: [s.plan])
        XCTAssertEqual(TransferLines.sentCount(rows(s)), 2)

        s.items["Kos"]?.recordMoved()
        XCTAssertEqual(TransferLines.sentCount(rows(s)), 2, "BCA part in is not sent")
    }

    /// The line keeps its place: planned total ↓, whatever is in.
    @MainActor
    func testLinesKeepTheirOrderWhenTheirStateChanges() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let before = rows(s).map(\.accountName)
        s.items["Kos"]?.recordMoved()
        XCTAssertEqual(rows(s).map(\.accountName), before)
        XCTAssertEqual(before, ["BNI", "CC Danamon", "Mandiri", "BCA", "Cash"])
    }

    // MARK: - §6 The sheet

    /// Every Todo item chosen, ordered by due day in cycle, the undated after (AD2).
    @MainActor
    func testTheSheetOpensWithEveryTodoItemChosenInDueOrder() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let bca = try row("BCA", s)
        let pick = TransferPick(row: bca, chosen: TransferPick.initialChoice(for: bca))

        XCTAssertEqual(names(pick.toSend), ["Gym membership", "Kos", "Listrik Kos"])
        XCTAssertEqual(pick.chosenMembers.count, 3)
        XCTAssertEqual(pick.sendTitle, "To send · 3 of 3")
        XCTAssertEqual(pick.transferNow, 2_747_300)
        XCTAssertEqual(pick.recordEntry.title, "Moved to BCA")
        XCTAssertEqual(pick.toSend.first?.caption, "Kesehatan · Auto · Due 1")
        XCTAssertEqual(pick.toSend.last?.caption, "Utilitas")
        XCTAssertTrue(pick.alreadyIn.isEmpty)
    }

    /// Transfer now follows the choice; nothing chosen moves nothing (AD3, D5).
    @MainActor
    func testTransferNowFollowsTheChoice() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let bca = try row("BCA", s)
        let kos = try XCTUnwrap(bca.members.first { $0.name == "Kos" })

        let kosOnly = TransferPick(row: bca, chosen: [kos.id])
        XCTAssertEqual(kosOnly.transferNow, 2_200_000)
        XCTAssertEqual(kosOnly.sendTitle, "To send · 1 of 3")
        XCTAssertTrue(kosOnly.canRecord)

        let none = TransferPick(row: bca, chosen: [])
        XCTAssertEqual(none.transferNow, 0)
        XCTAssertFalse(none.canRecord)
    }

    /// In the first round the adjustment is in Transfer now, never below zero.
    @MainActor
    func testAnUntakenAdjustmentCountsInTransferNow() throws {
        let context = try makeInMemoryContext()
        let superbank = Account(name: "Superbank")
        context.insert(superbank)
        let tabungan = PlanItem(name: "Tabungan", amount: 3_000_000, account: superbank)
        let darurat = PlanItem(name: "Dana darurat", amount: 1_000_000, account: superbank)
        [tabungan, darurat].forEach(context.insert)
        let line = TransferLine(account: superbank, adjustment: -700_000)
        context.insert(line)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: [tabungan, darurat], lines: [line]).first)
        XCTAssertEqual(TransferPick(row: row, chosen: [tabungan.persistentModelID]).transferNow, 2_300_000)
        XCTAssertEqual(TransferPick(row: row, chosen: [darurat.persistentModelID]).transferNow, 300_000)
        XCTAssertNil(TransferPick(row: row, chosen: []).adjustmentNote)

        tabungan.recordMoved()
        let second = try XCTUnwrap(TransferLines.rows(activeItems: [tabungan, darurat], lines: [line]).first)
        XCTAssertEqual(TransferPick(row: second, chosen: [darurat.persistentModelID]).transferNow, 1_000_000)
    }

    /// Every chosen item Auto reads "Covered in", the Auto menu's words (D4).
    @MainActor
    func testAnAllAutoChoiceRecordsAsCovered() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let bca = try row("BCA", s)
        let gym = try XCTUnwrap(bca.members.first { $0.name == "Gym membership" })
        XCTAssertEqual(TransferPick(row: bca, chosen: [gym.id]).recordEntry.title, "Covered in BCA")
    }

    /// Recording sets the chosen items Funded; a set-aside line is moved, i.e. Done.
    @MainActor
    func testRecordingMakesTheChosenItemsIn() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let kos = try XCTUnwrap(s.items["Kos"])
        kos.recordMoved()
        XCTAssertEqual(PlanItemState.of(kos), .funded)

        let jago = Account(name: "Jago")
        context.insert(jago)
        let setAside = PlanItem(name: "Jepang", amount: 1_000_000, kind: .setAside, account: jago)
        context.insert(setAside)
        setAside.recordMoved()
        XCTAssertEqual(PlanItemState.of(setAside), .done)
    }

    /// ALREADY IN: Funded rows offer their own undo, a Done row none (AD5, AD6).
    @MainActor
    func testAlreadyInRowsOfferTheirOwnUndo() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        PlanMaintenance.convertSentTicks(in: [s.plan])
        s.items["Kos"]?.recordMoved()

        let kos = try XCTUnwrap(try row("BCA", s).members.first { $0.name == "Kos" })
        XCTAssertEqual(kos.undoEntry, .notMoved)
        XCTAssertEqual(kos.inCaption(accountName: "BCA"), "in BCA")

        let cicilan = try XCTUnwrap(try row("BNI", s).members.first)
        XCTAssertEqual(cicilan.undoEntry, .notCovered)
        XCTAssertEqual(cicilan.inCaption(accountName: "BNI"), "covered in BNI")

        let tagihan = try XCTUnwrap(try row("Mandiri", s).members.first { $0.name == "Tagihan Handphone Ibu" })
        XCTAssertNil(tagihan.undoEntry)
        XCTAssertEqual(tagihan.inCaption(accountName: "Mandiri"), "Tagihan · paid")
    }

    /// Not moved yet puts the item back under To send, not chosen (§6.3).
    @MainActor
    func testNotMovedYetReturnsTheItemUnchosen() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let kos = try XCTUnwrap(s.items["Kos"])
        kos.recordMoved()
        let opened = try row("BCA", s)
        let chosen = TransferPick.initialChoice(for: opened)

        kos.apply(.notMoved)
        let pick = TransferPick(row: try row("BCA", s), chosen: chosen)
        XCTAssertEqual(names(pick.toSend), ["Gym membership", "Kos", "Listrik Kos"])
        XCTAssertFalse(pick.isChosen(try XCTUnwrap(pick.toSend.first { $0.name == "Kos" })))
        XCTAssertEqual(pick.sendTitle, "To send · 2 of 3")
    }

    /// All in: nothing to send, the line's total, and the message (AD7).
    @MainActor
    func testAnAllInLineHasNothingToSend() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        PlanMaintenance.convertSentTicks(in: [s.plan])
        let bni = try row("BNI", s)
        let pick = TransferPick(row: bni, chosen: TransferPick.initialChoice(for: bni))

        XCTAssertTrue(pick.toSend.isEmpty)
        XCTAssertEqual(pick.figureTitle, "Total")
        XCTAssertEqual(pick.figure, 7_706_000)
        XCTAssertEqual(pick.allInMessage, "Everything for BNI is in.")
        XCTAssertEqual(pick.alreadyInTitle, "Already in BNI")
    }

    // MARK: - §7 Lifetime

    /// Carry-over starts every item Todo (payday-planning.md §7.2), so every line of
    /// the new plan reads nothing in.
    @MainActor
    func testANewCycleStartsEveryLineWithNothingIn() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        PlanMaintenance.convertSentTicks(in: [s.plan])
        let next = cycle.next(payday: 25, calendar: calendar)

        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: next, from: [s.plan], in: context))
        let items = PlanDormancy.split(copy.items ?? []).active
        let fresh = TransferLines.rows(activeItems: items, lines: copy.transferLines ?? [])
        XCTAssertFalse(fresh.isEmpty)
        XCTAssertTrue(fresh.allSatisfy { $0.fill == .nothingIn })
    }
}
