//
//  PlanCarryOverTests.swift
//  ExpenseKuTests
//
//  Copying a plan forward (PRD §7.2). What is *not* copied is most of the point:
//  doneness, the Expense link, needs-review and "sudah masuk" all belong to the cycle
//  that ended, and carrying any of them would open the new cycle with work already
//  claimed as finished.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanCarryOverTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int, _ d: Int) -> PayCycle {
        PayCycle.containing(date(y, m, d), payday: 1, calendar: calendar)
    }

    /// Everything copies, amounts and due days included — a due day is a day-of-month
    /// precisely so it survives this without re-entry.
    @MainActor
    func testEverythingIsCopied() throws {
        let context = try makeInMemoryContext()
        let september = cycle(2026, 9, 10)
        let source = CyclePlan(cycleStart: september.start)
        context.insert(source)
        let makan = Category(name: "Makan")
        context.insert(makan)
        context.insert(IncomeLine(name: "Gaji", amount: 20_000_000, hasArrived: true, plan: source))
        context.insert(PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 20,
                                isAuto: true, plan: source, category: makan))
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: source, envelopeCategories: [makan]))
        try context.save()

        let october = cycle(2026, 10, 10)
        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: october, from: [source], in: context))

        XCTAssertEqual(copy.cycleStart, october.start)
        XCTAssertEqual(copy.items?.count, 2)
        XCTAssertEqual(copy.incomeLines?.count, 1)
        let fixed = try XCTUnwrap((copy.items ?? []).first { $0.name == "Cicilan Rumah BNI" })
        XCTAssertEqual(fixed.amount, 7_706_000)
        XCTAssertEqual(fixed.dueDay, 20)
        XCTAssertTrue(fixed.isAuto)
        XCTAssertEqual(fixed.category?.name, "Makan")
        let envelope = try XCTUnwrap((copy.items ?? []).first { $0.kind == .envelope })
        XCTAssertEqual(envelope.envelopeCategories?.count, 1)
    }

    /// **Doneness never travels.** The new cycle opens with everything still to do.
    @MainActor
    func testDonenessAndArrivalAreNotCopied() throws {
        let context = try makeInMemoryContext()
        let source = CyclePlan(cycleStart: cycle(2026, 9, 10).start)
        context.insert(source)
        let item = PlanItem(name: "Kos", amount: 2_200_000, plan: source)
        context.insert(item)
        context.insert(Expense(amount: 2_500_000, planItem: item, needsReview: true))
        context.insert(IncomeLine(name: "Gaji", amount: 20_000_000, hasArrived: true, plan: source))
        try context.save()
        XCTAssertTrue(item.isDone)

        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: cycle(2026, 10, 10),
                                                        from: [source], in: context))
        let copied = try XCTUnwrap(copy.items?.first)
        XCTAssertFalse(copied.isDone)
        XCTAssertTrue(copied.linkedExpenses?.isEmpty ?? true)
        XCTAssertEqual(copied.amount, 2_200_000, "the plan is copied, not the actual")
        XCTAssertFalse(copy.incomeLines?.first?.hasArrived ?? true)
    }

    /// Transfer ticks and adjustments are a fact about one payday, so they never
    /// travel either.
    @MainActor
    func testTransferLinesAreNotCopied() throws {
        let context = try makeInMemoryContext()
        let source = CyclePlan(cycleStart: cycle(2026, 9, 10).start)
        context.insert(source)
        let bca = Account(name: "BCA")
        context.insert(bca)
        context.insert(TransferLine(account: bca, adjustment: -700_000,
                                    hasTransferred: true, plan: source))
        try context.save()

        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: cycle(2026, 10, 10),
                                                        from: [source], in: context))
        XCTAssertTrue(copy.transferLines?.isEmpty ?? true)
    }

    /// Copied rows are marked as such and carry when they last mattered, so a row
    /// dormant for months can still name the cycle it was last used in.
    @MainActor
    func testCopiedRowsRecordWhereTheyCameFrom() throws {
        let context = try makeInMemoryContext()
        let september = cycle(2026, 9, 10)
        let source = CyclePlan(cycleStart: september.start)
        context.insert(source)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: source))
        context.insert(PlanItem(name: "Liburan Saving", amount: 0,
                                lastUsedCycleStart: date(2026, 3, 1),
                                carriedOver: true, plan: source))
        try context.save()

        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: cycle(2026, 10, 10),
                                                        from: [source], in: context))
        XCTAssertEqual(copy.copiedFromCycleStart, september.start)
        XCTAssertEqual(copy.copiedItemCount, 1,
                       "the notice counts live rows only — the dormant one is folded away, "
                       + "and the sentence sits directly above a list headed with the live count")

        let inUse = try XCTUnwrap((copy.items ?? []).first { $0.name == "Kos" })
        XCTAssertEqual(inUse.lastUsedCycleStart, september.start)
        XCTAssertTrue(inUse.carriedOver)
        XCTAssertFalse(PlanDormancy.isDormant(inUse), "money against it means it is live")

        let dormant = try XCTUnwrap((copy.items ?? []).first { $0.name == "Liburan Saving" })
        XCTAssertEqual(dormant.lastUsedCycleStart, date(2026, 3, 1),
                       "an unused row keeps the older date rather than claiming September")
        XCTAssertTrue(PlanDormancy.isDormant(dormant))
    }

    /// A cycle that already has a plan is never overwritten.
    @MainActor
    func testACycleWithAPlanIsLeftAlone() throws {
        let context = try makeInMemoryContext()
        let october = cycle(2026, 10, 10)
        let existing = CyclePlan(cycleStart: october.start)
        let source = CyclePlan(cycleStart: cycle(2026, 9, 10).start)
        context.insert(existing)
        context.insert(source)
        try context.save()

        XCTAssertNil(PlanCarryOver.makePlan(for: october, from: [source, existing], in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CyclePlan>()), 2)
    }

    /// With nothing to copy from, nothing is made — the owner gets the empty state and
    /// types their first cycle by hand (frame I5, §4 no importer).
    @MainActor
    func testTheFirstCycleHasNothingToCopy() throws {
        let context = try makeInMemoryContext()
        XCTAssertNil(PlanCarryOver.makePlan(for: cycle(2026, 9, 10), from: [], in: context))
    }

    /// Copying twice does not double the plan.
    @MainActor
    func testCopyingIsIdempotent() throws {
        let context = try makeInMemoryContext()
        let source = CyclePlan(cycleStart: cycle(2026, 9, 10).start)
        context.insert(source)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: source))
        try context.save()

        let october = cycle(2026, 10, 10)
        let first = PlanCarryOver.makePlan(for: october, from: [source], in: context)
        let plans = try context.fetch(FetchDescriptor<CyclePlan>())
        let second = PlanCarryOver.makePlan(for: october, from: plans, in: context)
        XCTAssertNotNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 2)
    }
}
