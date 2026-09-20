//
//  TransferLinesTests.swift
//  ExpenseKuTests
//
//  The payday checklist (PRD §7.5). Two rules here look like special cases and are
//  not, both verified against nine cycles of the spreadsheet: an Auto item still
//  contributes to its account's line, and a credit card is summed exactly like every
//  other account.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class TransferLinesTests: XCTestCase {

    /// One row per account, largest first, summing the items paid from it.
    @MainActor
    func testRowsSumByAccountLargestFirst() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI")
        let bca = Account(name: "BCA")
        [bni, bca].forEach(context.insert)
        let items = [PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, account: bni),
                     PlanItem(name: "Kos", amount: 2_200_000, account: bca),
                     PlanItem(name: "Listrik", amount: 200_000, account: bca)]
        items.forEach(context.insert)
        try context.save()

        let rows = TransferLines.rows(activeItems: items, lines: [])
        XCTAssertEqual(rows.map(\.accountName), ["BNI", "BCA"])
        XCTAssertEqual(rows[0].planned, 7_706_000)
        XCTAssertEqual(rows[1].planned, 2_400_000)
    }

    /// **ADR-0007.** `ke BNI Rp 7.706.000` is an Auto row. Auto does not mean "leave
    /// it off the list" — the line means "keep enough here for the debit to clear".
    @MainActor
    func testAnAutoItemStillContributes() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI")
        context.insert(bni)
        let item = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 20,
                            isAuto: true, account: bni)
        context.insert(item)
        try context.save()

        let rows = TransferLines.rows(activeItems: [item], lines: [])
        XCTAssertEqual(rows.first?.planned, 7_706_000)
        XCTAssertTrue(rows.first?.allAuto == true, "an all-Auto account reads 'keep this covered'")
    }

    /// An envelope has no account and never reaches the checklist.
    @MainActor
    func testEnvelopesNeverContribute() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let fixed = PlanItem(name: "Kos", amount: 2_200_000, account: bca)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: bca)
        context.insert(fixed)
        context.insert(envelope)
        try context.save()

        let rows = TransferLines.rows(activeItems: [fixed, envelope], lines: [])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.planned, 2_200_000)
    }

    /// The manual adjustment is signed, and the transfer figure is what the owner
    /// actually moves: "ke Superbank −Rp 700.000" because that money is already there.
    @MainActor
    func testTheAdjustmentIsSignedAndChangesTheTransferNotThePlan() throws {
        let context = try makeInMemoryContext()
        let superbank = Account(name: "Superbank")
        context.insert(superbank)
        let item = PlanItem(name: "Tabungan", amount: 1_258_700, account: superbank)
        let line = TransferLine(account: superbank, adjustment: -700_000)
        context.insert(item)
        context.insert(line)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: [item], lines: [line]).first)
        XCTAssertEqual(row.planned, 1_258_700)
        XCTAssertEqual(row.adjustment, -700_000)
        XCTAssertEqual(row.transfer, 558_700)
        XCTAssertTrue(row.hasAdjustment)
    }

    /// An account with no TransferLine still shows its derived total — the line only
    /// exists once the owner has ticked or adjusted something.
    @MainActor
    func testAnAccountWithNoLineStillAppears() throws {
        let context = try makeInMemoryContext()
        let cash = Account(name: "Cash")
        context.insert(cash)
        let item = PlanItem(name: "Jajan", amount: 650_000, account: cash)
        context.insert(item)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: [item], lines: []).first)
        XCTAssertEqual(row.transfer, 650_000)
        XCTAssertFalse(row.hasTransferred)
        XCTAssertFalse(row.hasAdjustment)
    }

    /// An item with no account is not a transfer at all and produces no row.
    @MainActor
    func testItemsWithNoAccountProduceNoRow() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "THR fara-eja-tarisa", amount: 3_000_000)
        context.insert(item)
        try context.save()
        XCTAssertTrue(TransferLines.rows(activeItems: [item], lines: []).isEmpty)
    }

    /// E3's "2 OF 6 SENT".
    @MainActor
    func testSentCount() throws {
        let context = try makeInMemoryContext()
        let a = Account(name: "BNI"), b = Account(name: "BCA")
        [a, b].forEach(context.insert)
        let items = [PlanItem(name: "x", amount: 2, account: a),
                     PlanItem(name: "y", amount: 1, account: b)]
        items.forEach(context.insert)
        let line = TransferLine(account: a, hasTransferred: true)
        context.insert(line)
        try context.save()

        let rows = TransferLines.rows(activeItems: items, lines: [line])
        XCTAssertEqual(TransferLines.sentCount(rows), 1)
    }
}
