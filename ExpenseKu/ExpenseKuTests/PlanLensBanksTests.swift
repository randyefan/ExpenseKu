//
//  PlanLensBanksTests.swift
//  ExpenseKuTests
//
//  The Plan lens's banks (docs/prd/bank-logos.md §5.6): the state a bank header reads,
//  its total and count, and the Transfer checklist's caption. The fixture is flow AA's
//  October plan — payday 25, so the cycle runs 25 Oct → 24 Nov 2026.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PlanLensBanksTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private var cycle: PayCycle {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)) ?? .distantPast
        return PayCycle.containing(day, payday: 25, calendar: calendar)
    }

    @MainActor
    private func done(_ item: PlanItem, in context: ModelContext) {
        context.insert(Expense(amount: item.amount, planItem: item))
    }

    // MARK: - §5.6.2 The header's state

    @MainActor
    func testEveryItemTodoReadsNothingInYet() throws {
        let context = try makeInMemoryContext()
        let danamon = Account(name: "CC Danamon")
        context.insert(danamon)
        let items = [PlanItem(name: "Cicil ke Kartu Kredit", amount: 4_700_000, dueDay: 20, isAuto: true, account: danamon),
                     PlanItem(name: "Netflix", amount: 130_000, dueDay: 12, isAuto: true, account: danamon)]
        items.forEach(context.insert)

        let state = AccountGroupState.of(items, hasAccount: true)
        XCTAssertEqual(state, .nothingIn)
        XCTAssertEqual(state.text(accountName: "CC Danamon"), "nothing in yet")
    }

    @MainActor
    func testSomeTodoReadsWhatIsStillToGo() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let kos = PlanItem(name: "Kos", amount: 2_200_000, dueDay: 1, account: bca)
        let tarisa = PlanItem(name: "Tarisa Needs", amount: 1_500_000, account: bca)
        let listrik = PlanItem(name: "Listrik Kos", amount: 247_300, dueDay: 28, account: bca)
        [kos, tarisa, listrik].forEach(context.insert)
        done(kos, in: context)
        done(listrik, in: context)
        try context.save()

        let state = AccountGroupState.of([kos, tarisa, listrik], hasAccount: true)
        XCTAssertEqual(state, .toGo(1_500_000), "only the Todo items count")
        XCTAssertEqual(state.text(accountName: "BCA"), "\(Decimal(1_500_000).formattedIDR()) to go")
    }

    @MainActor
    func testAFundedItemAmongTodoStillReadsToGo() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let kos = PlanItem(name: "Kos", amount: 2_200_000, account: bca)
        let tarisa = PlanItem(name: "Tarisa Needs", amount: 1_500_000, account: bca)
        [kos, tarisa].forEach(context.insert)
        kos.isFunded = true

        XCTAssertEqual(AccountGroupState.of([kos, tarisa], hasAccount: true), .toGo(1_500_000))
    }

    @MainActor
    func testNoTodoWithAFundedItemReadsAllInTheAccount() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let ibu = PlanItem(name: "Kirim buat Ibu", amount: 2_000_000, account: mandiri)
        let pulsa = PlanItem(name: "Pulsa", amount: 100_000, account: mandiri)
        [ibu, pulsa].forEach(context.insert)
        ibu.isFunded = true
        done(pulsa, in: context)
        try context.save()

        let state = AccountGroupState.of([ibu, pulsa], hasAccount: true)
        XCTAssertEqual(state, .allIn)
        XCTAssertEqual(state.text(accountName: "Mandiri"), "all in Mandiri")
    }

    @MainActor
    func testEveryItemDoneReadsAllPaid() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let ibu = PlanItem(name: "Kirim buat Ibu", amount: 2_000_000, account: mandiri)
        context.insert(ibu)
        done(ibu, in: context)
        try context.save()

        let state = AccountGroupState.of([ibu], hasAccount: true)
        XCTAssertEqual(state, .allPaid)
        XCTAssertEqual(state.text(accountName: "Mandiri"), "all paid")
    }

    /// An Envelope's last state is Funded, and a Funded Auto item's Account covers the
    /// debit: both follow the same rule as any item.
    @MainActor
    func testEnvelopesAndAutoItemsFollowTheSameRule() throws {
        let context = try makeInMemoryContext()
        let jago = Account(name: "Jago")
        let bni = Account(name: "BNI")
        [jago, bni].forEach(context.insert)
        let hidup = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago)
        let cicilan = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 5, isAuto: true, account: bni)
        [hidup, cicilan].forEach(context.insert)
        XCTAssertEqual(AccountGroupState.of([hidup], hasAccount: true), .nothingIn)

        hidup.isFunded = true
        cicilan.isFunded = true
        XCTAssertEqual(AccountGroupState.of([hidup], hasAccount: true), .allIn)
        XCTAssertEqual(AccountGroupState.of([cicilan], hasAccount: true), .allIn)
    }

    @MainActor
    func testASetAsideLineIsTodoUntilMovedThenDone() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let line = PlanItem(name: "", amount: 1_000_000, kind: .setAside, account: bca)
        context.insert(line)
        XCTAssertEqual(AccountGroupState.of([line], hasAccount: true), .nothingIn)

        line.isSetAsideMoved = true
        XCTAssertEqual(AccountGroupState.of([line], hasAccount: true), .allPaid)
    }

    /// No Account means nowhere for money to be "in": every Todo item is simply to go.
    @MainActor
    func testUnassignedReadsOnlyToGoOrAllPaid() throws {
        let context = try makeInMemoryContext()
        let arisan = PlanItem(name: "Arisan", amount: 300_000)
        context.insert(arisan)
        XCTAssertEqual(AccountGroupState.of([arisan], hasAccount: false), .toGo(300_000))

        done(arisan, in: context)
        try context.save()
        XCTAssertEqual(AccountGroupState.of([arisan], hasAccount: false), .allPaid)
    }

    // MARK: - §5.6.2 Total and count

    @MainActor
    func testTheTotalIsTheSumOfTheRowsNotTheTransferFigure() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let items = [PlanItem(name: "Kos", amount: 2_200_000, account: bca),
                     PlanItem(name: "Tarisa Needs", amount: 1_500_000, account: bca),
                     PlanItem(name: "Listrik Kos", amount: 247_300, account: bca)]
        items.forEach(context.insert)
        context.insert(TransferLine(account: bca, adjustment: -500_000))
        try context.save()

        let summary = AccountGroupSummary(items: items, hasAccount: true)
        XCTAssertEqual(summary.total, 3_947_300)
        XCTAssertEqual(summary.count, "3 items")
    }

    // MARK: - §5.6.5 The count

    func testTheCountNamesEnvelopesApart() {
        XCTAssertEqual(PlanCopy.itemCount(items: 1, envelopes: 0), "1 item")
        XCTAssertEqual(PlanCopy.itemCount(items: 2, envelopes: 0), "2 items")
        XCTAssertEqual(PlanCopy.itemCount(items: 0, envelopes: 1), "1 envelope")
        XCTAssertEqual(PlanCopy.itemCount(items: 0, envelopes: 2), "2 envelopes")
        XCTAssertEqual(PlanCopy.itemCount(items: 1, envelopes: 1), "1 item, 1 envelope")
    }

    @MainActor
    func testASetAsideLineCountsAsAnItem() throws {
        let context = try makeInMemoryContext()
        let items = [PlanItem(name: "", amount: 1_000_000, kind: .setAside),
                     PlanItem(name: "Hidup", amount: 938_300, kind: .envelope)]
        items.forEach(context.insert)
        XCTAssertEqual(PlanCopy.itemCount(items), "1 item, 1 envelope")
    }

    // MARK: - §5.6.4 The Transfer checklist

    func testDueDaysStopAfterThree() {
        XCTAssertNil(PlanCopy.dueDays([]))
        XCTAssertEqual(PlanCopy.dueDays([12, 20]), "Due 12, 20")
        XCTAssertEqual(PlanCopy.dueDays([1, 5, 12, 20]), "Due 1, 5, 12, …")
    }

    /// With payday 25 the cycle opens on the 25th, so Due 28 leaves before Due 1; a day
    /// two items share is named once.
    @MainActor
    func testDueDaysRunInCycleOrderEachOnce() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let items = [PlanItem(name: "Kos", amount: 2_200_000, dueDay: 1, account: bca),
                     PlanItem(name: "Tarisa Needs", amount: 1_500_000, account: bca),
                     PlanItem(name: "Listrik Kos", amount: 247_300, dueDay: 28, account: bca),
                     PlanItem(name: "Air", amount: 80_000, dueDay: 1, account: bca)]
        items.forEach(context.insert)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: items, lines: [], cycle: cycle, calendar: calendar).first)
        XCTAssertEqual(row.dueDays, [28, 1])
        XCTAssertEqual(row.caption, "4 items · Due 28, 1")
    }

    @MainActor
    func testAnAllAutoLineAddsItsNoteAfterTheCount() throws {
        let context = try makeInMemoryContext()
        let danamon = Account(name: "CC Danamon")
        context.insert(danamon)
        let items = [PlanItem(name: "Cicil ke Kartu Kredit", amount: 4_700_000, dueDay: 20, isAuto: true, account: danamon),
                     PlanItem(name: "Netflix", amount: 130_000, dueDay: 12, isAuto: true, account: danamon)]
        items.forEach(context.insert)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: items, lines: [], cycle: cycle, calendar: calendar).first)
        XCTAssertEqual(row.caption, "2 items · Due 12, 20 · Auto debit — keep this covered")
    }

    /// An adjustment speaks instead of "keep this covered", as the line always did.
    @MainActor
    func testAnAdjustmentFollowsTheCountAndSilencesTheAutoNote() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI")
        context.insert(bni)
        let item = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 5, isAuto: true, account: bni)
        let line = TransferLine(account: bni, adjustment: -706_000)
        [item].forEach(context.insert)
        context.insert(line)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: [item], lines: [line], cycle: cycle, calendar: calendar).first)
        XCTAssertEqual(row.caption, "1 item · Due 5 · \(Decimal(-706_000).formattedIDR()) adjustment applied")
    }

    @MainActor
    func testAnEnvelopeOnlyLineCountsEnvelopesAndHasNoDueDays() throws {
        let context = try makeInMemoryContext()
        let jago = Account(name: "Jago")
        jago.brandID = "jago"
        context.insert(jago)
        let hidup = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago)
        context.insert(hidup)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: [hidup], lines: [], cycle: cycle, calendar: calendar).first)
        XCTAssertEqual(row.caption, "1 envelope")
        XCTAssertEqual(row.plate, AccountPlateStyle(account: jago), "the line's plate draws its Account")
        XCTAssertEqual(row.plate?.brandID, "jago")
    }

    // MARK: - §5.6.2 Rows inside a bank group

    @MainActor
    func testOnlyTheAccountOrderMakesBankGroups() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let items = [PlanItem(name: "Kos", amount: 2_200_000, dueDay: 1, account: bca),
                     PlanItem(name: "Arisan", amount: 300_000)]
        items.forEach(context.insert)

        let byAccount = PlanSections.sections(items, by: .account, cycle: cycle, calendar: calendar)
        XCTAssertEqual(byAccount.map(\.isAccountGroup), [true, true], "Unassigned is a bank group too")
        for sort in [PlanSort.amount, .dueDay, .group, .status, .name] {
            let sections = PlanSections.sections(items, by: sort, cycle: cycle, calendar: calendar)
            XCTAssertFalse(sections.contains(where: \.isAccountGroup), "\(sort)")
        }
    }
}
