//
//  PaidElsewhereTests.swift
//  ExpenseKuTests
//
//  Flow AE (docs/prd/paid-elsewhere.md), against the PRD's own sample (§7): payday 25,
//  November 2026 (25 Oct – 24 Nov). Travelling is Rp 2.000.000 kept in Jago, and a
//  Bandung trip on 28 Oct went on CC Danamon, Cash, BCA, Jago and no Account at all.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PaidElsewhereTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()
    private let payday = 25

    private func date(_ m: Int, _ d: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: 12, minute: minute)) ?? .distantPast
    }

    private var november: PayCycle { PayCycle.containing(date(11, 1), payday: payday, calendar: calendar) }

    private struct Sample {
        let travelling: PlanItem
        let accounts: [String: Account]
        let categories: [String: Category]
        let expenses: [String: Expense]
        var all: [Expense] { Array(expenses.values) }
    }

    @MainActor
    private func sample(in context: ModelContext, envelopeAccount: String? = "Jago") throws -> Sample {
        let categories = Dictionary(uniqueKeysWithValues: ["Makan", "Bensin", "Sewa", "Transport", "Hiburan"]
            .map { ($0, Category(name: $0)) })
        categories.values.forEach(context.insert)
        let accounts = Dictionary(uniqueKeysWithValues: ["Jago", "CC Danamon", "Cash", "BCA"]
            .map { ($0, Account(name: $0)) })
        accounts.values.forEach(context.insert)

        let plan = CyclePlan(cycleStart: date(10, 25))
        context.insert(plan)
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: plan,
                                  account: envelopeAccount.flatMap { accounts[$0] })
        context.insert(travelling)

        let spec: [(String, Decimal, String, String?, Bool)] = [
            ("Nasi Padang Bandung", 85_000, "Makan", "Cash", false),
            ("Bensin ke Bandung", 150_000, "Bensin", "Jago", false),
            ("Hotel Bandung", 450_000, "Sewa", "CC Danamon", false),
            ("Grab ke hotel", 65_000, "Transport", "CC Danamon", false),
            ("Grab ke stasiun", 48_000, "Transport", "CC Danamon", false),
            ("Oleh-oleh", 120_000, "Makan", nil, false),
            ("Tiket Kawah Putih", 35_000, "Hiburan", "BCA", true),
        ]
        var expenses: [String: Expense] = [:]
        for (offset, (note, amount, category, account, moved)) in spec.enumerated() {
            let expense = Expense(amount: amount, date: date(10, 28, minute: offset), note: note,
                                  category: categories[category], account: account.flatMap { accounts[$0] })
            context.insert(expense)
            expense.envelope = travelling
            expense.isMovedFromEnvelope = moved
            expenses[note] = expense
        }
        try context.save()
        return Sample(travelling: travelling, accounts: accounts, categories: categories, expenses: expenses)
    }

    private func paidElsewhere(_ sample: Sample, extra: [Expense] = []) -> PaidElsewhere {
        let claims = EnvelopeClaims(envelopes: EnvelopeOffer.activeEnvelopes(of: sample.travelling.plan), cycle: november)
        let detail = EnvelopeDetail(envelope: sample.travelling, claims: claims,
                                    cycleExpenses: sample.all.filter { november.contains($0.date) } + extra,
                                    payday: payday, calendar: calendar)
        return PaidElsewhere(envelope: sample.travelling, expenses: detail.expenses, calendar: calendar)
    }

    private func row(_ result: PaidElsewhere, _ name: String) throws -> PaidElsewhereRow {
        try XCTUnwrap(result.rows.first { $0.accountName == name })
    }

    // MARK: - §4.1–§4.4, AE1

    /// AE1: one row per other Account, those still to move first by what is left, the
    /// all-moved BCA last.
    @MainActor
    func testAE1RowsOrderAndFigures() throws {
        let result = paidElsewhere(try sample(in: try makeInMemoryContext()))

        XCTAssertEqual(result.rows.map(\.accountName), ["CC Danamon", "Cash", "BCA"])
        XCTAssertEqual(result.rows.map(\.total), [563_000, 85_000, 35_000])
        XCTAssertEqual(result.rows.map(\.fill), [.nothingIn, .nothingIn, .allIn])
        XCTAssertEqual(result.rows.map(\.caption), ["Move from Jago", "Move from Jago", "Moved from Jago"])
    }

    /// §4.1, §4.2: the envelope's own Account and an expense with no Account are not paid
    /// elsewhere; setting an Account on the latter brings it in.
    @MainActor
    func testOwnAccountAndUnassignedAreLeftOut() throws {
        let sample = try sample(in: try makeInMemoryContext())
        let names = paidElsewhere(sample).rows.flatMap(\.members).map(\.note)
        XCTAssertFalse(names.contains("Bensin ke Bandung"))
        XCTAssertFalse(names.contains("Oleh-oleh"))

        try XCTUnwrap(sample.expenses["Oleh-oleh"]).account = sample.accounts["CC Danamon"]
        XCTAssertEqual(try row(paidElsewhere(sample), "CC Danamon").total, 683_000)
    }

    /// D1: an envelope with no Account has nowhere to move from, so no section.
    @MainActor
    func testAnEnvelopeWithNoAccountHasNoSection() throws {
        let result = paidElsewhere(try sample(in: try makeInMemoryContext(), envelopeAccount: nil))
        XCTAssertTrue(result.isEmpty)
    }

    /// D2: an expense paid early from October into November's Travelling is listed too.
    @MainActor
    func testPaidEarlyExpensesAreIncluded() throws {
        let context = try makeInMemoryContext()
        let sample = try sample(in: context)
        let ticket = Expense(amount: 1_200_000, date: date(10, 14), note: "Tiket KAI",
                             category: sample.categories["Transport"], account: sample.accounts["CC Danamon"])
        context.insert(ticket)
        ticket.envelope = sample.travelling
        try context.save()

        let cc = try row(paidElsewhere(sample), "CC Danamon")
        XCTAssertEqual(cc.total, 1_763_000)
        XCTAssertEqual(cc.members.first?.note, "Tiket KAI", "date ↑ puts October's ticket first")
    }

    // MARK: - §4.6, AE4

    /// AE3 → AE4: Hotel and Grab ke hotel moved, Grab ke stasiun not. CC Danamon reads part
    /// moved and drops under Cash, which owes more.
    @MainActor
    func testAE4PartMovedRowReordersAndSplitsItsCaption() throws {
        let sample = try sample(in: try makeInMemoryContext())
        try XCTUnwrap(sample.expenses["Hotel Bandung"]).isMovedFromEnvelope = true
        try XCTUnwrap(sample.expenses["Grab ke hotel"]).isMovedFromEnvelope = true

        let result = paidElsewhere(sample)
        XCTAssertEqual(result.rows.map(\.accountName), ["Cash", "CC Danamon", "BCA"])
        let cc = try row(result, "CC Danamon")
        XCTAssertEqual(cc.fill, .partIn)
        XCTAssertEqual(cc.total, 563_000)
        XCTAssertEqual(cc.toMove, 48_000)
        XCTAssertEqual(cc.caption, "\(Decimal(48_000).formattedIDR()) to move · \(Decimal(515_000).formattedIDR()) moved")
    }

    /// Goal 3: a Grab logged after a round makes an all-moved row owe again by itself.
    @MainActor
    func testANewExpenseMakesAMovedRowOweAgain() throws {
        let context = try makeInMemoryContext()
        let sample = try sample(in: context)
        let grab = Expense(amount: 30_000, date: date(10, 29), note: "Grab ke rumah",
                           category: sample.categories["Transport"], account: sample.accounts["BCA"])
        context.insert(grab)
        grab.envelope = sample.travelling
        try context.save()

        let bca = try row(paidElsewhere(sample, extra: [grab]), "BCA")
        XCTAssertEqual(bca.fill, .partIn)
        XCTAssertEqual(bca.toMove, 30_000)
    }

    // MARK: - §4.5, AE2–AE6

    /// AE2: everything not moved is chosen, by date then amount, and Move now is its sum.
    @MainActor
    func testAE2SheetOpensWithEverythingChosen() throws {
        let cc = try row(paidElsewhere(try sample(in: try makeInMemoryContext())), "CC Danamon")
        let pick = PaidElsewherePick(row: cc, chosen: PaidElsewherePick.initialChoice(for: cc))

        XCTAssertEqual(pick.toMove.map(\.name), ["Hotel Bandung", "Grab ke hotel", "Grab ke stasiun"])
        XCTAssertEqual(pick.toMoveTitle, "To move · 3 of 3")
        XCTAssertEqual(pick.figureTitle, "Move now")
        XCTAssertEqual(pick.figure, 563_000)
        XCTAssertEqual(pick.title, "Move from Jago")
        XCTAssertEqual(pick.subtitle, "to CC Danamon")
        XCTAssertEqual(pick.recordTitle, "Moved from Jago")
        XCTAssertEqual(pick.toMove.first?.caption, "Oct 28 · Sewa")
    }

    /// AE3 and D5 of AD: unchoosing one drops it from Move now; nothing chosen records nothing.
    @MainActor
    func testAE3UnchoosingChangesMoveNow() throws {
        let sample = try sample(in: try makeInMemoryContext())
        let cc = try row(paidElsewhere(sample), "CC Danamon")
        let stasiun = try XCTUnwrap(sample.expenses["Grab ke stasiun"]).persistentModelID
        let pick = PaidElsewherePick(row: cc, chosen: PaidElsewherePick.initialChoice(for: cc).subtracting([stasiun]))

        XCTAssertEqual(pick.toMoveTitle, "To move · 2 of 3")
        XCTAssertEqual(pick.moveNow, 515_000)
        XCTAssertTrue(pick.canRecord)
        XCTAssertFalse(PaidElsewherePick(row: cc, chosen: []).canRecord)
    }

    /// AE6: with everything moved the sheet shows the total and the moved list only.
    @MainActor
    func testAE6EverythingMoved() throws {
        let bca = try row(paidElsewhere(try sample(in: try makeInMemoryContext())), "BCA")
        let pick = PaidElsewherePick(row: bca, chosen: PaidElsewherePick.initialChoice(for: bca))

        XCTAssertTrue(pick.toMove.isEmpty)
        XCTAssertEqual(pick.alreadyMoved.map(\.name), ["Tiket Kawah Putih"])
        XCTAssertEqual(pick.figureTitle, "Total")
        XCTAssertEqual(pick.figure, 35_000)
        XCTAssertEqual(pick.allMovedMessage, "Everything on BCA is moved.")
    }

    /// §4.5.1: a row with no note is named after its Category.
    @MainActor
    func testAnExpenseWithNoNoteIsNamedAfterItsCategory() throws {
        let sample = try sample(in: try makeInMemoryContext())
        try XCTUnwrap(sample.expenses["Hotel Bandung"]).note = ""
        let cc = try row(paidElsewhere(sample), "CC Danamon")
        XCTAssertEqual(cc.members.first?.name, "Sewa")
    }

    // MARK: - §4.6 clearing, D4

    /// The mark survives an unchanged Account; a new or cleared Account clears it.
    @MainActor
    func testChangingTheAccountClearsTheMark() throws {
        let sample = try sample(in: try makeInMemoryContext())
        let ticket = try XCTUnwrap(sample.expenses["Tiket Kawah Putih"])

        PaidElsewhere.setAccount(sample.accounts["BCA"], on: ticket)
        XCTAssertTrue(ticket.isMovedFromEnvelope)

        PaidElsewhere.setAccount(sample.accounts["Cash"], on: ticket)
        XCTAssertFalse(ticket.isMovedFromEnvelope)
        XCTAssertEqual(ticket.account?.name, "Cash")

        ticket.isMovedFromEnvelope = true
        PaidElsewhere.setAccount(nil, on: ticket)
        XCTAssertFalse(ticket.isMovedFromEnvelope)
    }

    /// The same envelope applied again keeps the mark; another choice clears it.
    @MainActor
    func testChangingTheEnvelopeClearsTheMark() throws {
        let sample = try sample(in: try makeInMemoryContext())
        let ticket = try XCTUnwrap(sample.expenses["Tiket Kawah Putih"])
        let envelopes = [sample.travelling]

        EnvelopeChoice.envelope(sample.travelling.persistentModelID).apply(to: ticket, envelopes: envelopes)
        XCTAssertTrue(ticket.isMovedFromEnvelope)

        EnvelopeChoice.byCategory.apply(to: ticket, envelopes: envelopes)
        XCTAssertFalse(ticket.isMovedFromEnvelope)

        ticket.isMovedFromEnvelope = true
        EnvelopeChoice.noEnvelope.apply(to: ticket, envelopes: envelopes)
        XCTAssertFalse(ticket.isMovedFromEnvelope)
    }

    /// D4: an amount edit keeps the mark — the owner reports the move, not a figure.
    @MainActor
    func testAnAmountEditKeepsTheMark() throws {
        let sample = try sample(in: try makeInMemoryContext())
        let ticket = try XCTUnwrap(sample.expenses["Tiket Kawah Putih"])
        ticket.amount = 40_000
        let bca = try row(paidElsewhere(sample), "BCA")
        XCTAssertEqual(bca.fill, .allIn)
        XCTAssertEqual(bca.total, 40_000)
    }
}
