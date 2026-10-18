//
//  LookBackTests.swift
//  ExpenseKuTests
//
//  docs/prd/look-back.md, one test per rule, on flow AB's own sample: November's plan
//  was copied from October; October then gained Service motor, Jajan and an amount on
//  Beli kado, and Perpanjang STNK was deleted from November.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class LookBackTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int) -> PayCycle {
        PayCycle.containing(date(y, m, 10), payday: 1, calendar: calendar)
    }

    @MainActor
    private final class Sample {
        let context: ModelContext
        let october: CyclePlan
        let november: CyclePlan
        var categories: [String: Category] = [:]
        var items: [String: PlanItem] = [:]

        init(context: ModelContext, october: PayCycle, november: PayCycle) {
            self.context = context
            self.october = CyclePlan(cycleStart: october.start)
            self.november = CyclePlan(cycleStart: november.start)
            context.insert(self.october)
            context.insert(self.november)
            for name in ["Makan", "Kopi", "Bensin", "Sewa", "Galon", "Kesehatan", "Hadiah", "Transport"] {
                let category = Category(name: name)
                context.insert(category)
                categories[name] = category
            }
        }

        @discardableResult
        func item(_ name: String, _ amount: Decimal, kind: PlanItemKind = .fixed, in plan: CyclePlan,
                  category: String? = nil, envelope: [String] = [], carriedOver: Bool = false) -> PlanItem {
            let item = PlanItem(name: name, amount: amount, kind: kind, carriedOver: carriedOver, plan: plan,
                                category: category.flatMap { categories[$0] },
                                envelopeCategories: envelope.compactMap { categories[$0] })
            context.insert(item)
            items["\(name)@\(plan.cycleStart)"] = item
            return item
        }

        @discardableResult
        func expense(_ amount: Decimal, on day: Date, _ category: String?, planItem: PlanItem? = nil) -> Expense {
            let expense = Expense(amount: amount, date: day, category: category.flatMap { categories[$0] },
                                  planItem: planItem)
            context.insert(expense)
            return expense
        }
    }

    /// Flow AB's sample, without the Outside plan spending.
    @MainActor
    private func sample() throws -> Sample {
        let s = Sample(context: try makeInMemoryContext(), october: cycle(2026, 10), november: cycle(2026, 11))
        s.item("Kos", 2_200_000, in: s.october, category: "Sewa")
        s.item("Kos", 2_400_000, in: s.november, category: "Sewa", carriedOver: true)
        s.item("Hidup", 938_300, kind: .envelope, in: s.october, envelope: ["Makan", "Bensin"])
        s.item("Hidup", 938_300, kind: .envelope, in: s.november, envelope: ["Makan", "Bensin"], carriedOver: true)
        s.item("Kebutuhan Kos di Jkt", 193_900, kind: .envelope, in: s.november, envelope: ["Galon"], carriedOver: true)
        let service = s.item("Service motor", 450_000, in: s.october, category: "Transport")
        s.expense(475_000, on: date(2026, 10, 20), "Transport", planItem: service)
        s.item("Jajan", 400_000, kind: .envelope, in: s.october, envelope: ["Kopi", "Makan"])
        s.item("Beli kado", 300_000, in: s.october, category: "Hadiah")
        s.item("Beli kado", 0, in: s.november, category: "Hadiah", carriedOver: true)
        s.item("Perpanjang STNK", 0, in: s.october, category: "Transport")
        try s.context.save()
        return s
    }

    @MainActor
    private func lookBack(_ s: Sample) -> LookBack {
        LookBack.of(cycle(2026, 10), here: s.november, plans: [s.october, s.november],
                    expenses: (try? s.context.fetch(FetchDescriptor<Expense>())) ?? [],
                    payday: 1, calendar: calendar)
    }

    // MARK: - §5.1 In October's plan, not here

    @MainActor
    func testItemsAddedAfterTheCopyAreListedInAmountOrderWithUnusedLast() throws {
        let rows = lookBack(try sample()).planRows
        XCTAssertEqual(rows.map(\.source.name), ["Service motor", "Jajan", "Beli kado", "Perpanjang STNK"])
        XCTAssertEqual(rows.map(\.isUnused), [false, false, false, true])
    }

    @MainActor
    func testAnItemPresentHereInAnyCaseOrSpacingIsNotListed() throws {
        let s = try sample()
        s.items["Kos@\(s.november.cycleStart)"]?.name = "  kos "
        XCTAssertFalse(lookBack(s).planRows.contains { $0.source.name == "Kos" })
    }

    @MainActor
    func testTheSameNameOfAnotherKindIsListed() throws {
        let s = try sample()
        s.item("Hiburan", 130_000, in: s.october)
        s.item("Hiburan", 200_000, kind: .envelope, in: s.november)
        XCTAssertTrue(lookBack(s).planRows.contains { $0.source.name == "Hiburan" })
    }

    @MainActor
    func testAMatchDormantHereIsOfferedWake() throws {
        let s = try sample()
        let row = try XCTUnwrap(lookBack(s).planRows.first { $0.source.name == "Beli kado" })
        guard case .wake(let dormant) = row.action else { return XCTFail("expected Wake") }
        XCTAssertEqual(dormant.persistentModelID, s.items["Beli kado@\(s.november.cycleStart)"]?.persistentModelID)
        XCTAssertEqual(row.caption, "dormant here")
    }

    @MainActor
    func testAnUnusedRowAlreadyHereIsNotListed() throws {
        let s = try sample()
        s.item("Perpanjang STNK", 0, in: s.november, carriedOver: true)
        XCTAssertFalse(lookBack(s).planRows.contains { $0.source.name == "Perpanjang STNK" })
    }

    @MainActor
    func testUnusedRowsReadRpZeroInTheirMonth() throws {
        let row = try XCTUnwrap(lookBack(try sample()).planRows.last)
        XCTAssertEqual(row.amountLine, "\(Decimal(0).formattedIDR()) in October")
    }

    @MainActor
    func testADoneItemPaidDifferentlySaysWhatWasPaid() throws {
        let row = try XCTUnwrap(lookBack(try sample()).planRows.first)
        XCTAssertEqual(row.caption, "paid \(Decimal(475_000).formattedIDR()) in October")
    }

    @MainActor
    func testAnEnvelopeNamesTheCategoriesItWillNotBring() throws {
        let row = try XCTUnwrap(lookBack(try sample()).planRows.first { $0.source.name == "Jajan" })
        XCTAssertEqual(row.caption, "Makan stays in Hidup")
        XCTAssertEqual(row.amountLine, "\(Decimal(400_000).formattedIDR()) · envelope")
    }

    @MainActor
    func testSetAsideLinesAreNeverListed() throws {
        let s = try sample()
        s.item("Jepang", 5_000_000, kind: .setAside, in: s.october)
        XCTAssertFalse(lookBack(s).planRows.contains { $0.source.isSetAside })
    }

    // MARK: - §5.2 Outside plan in October

    @MainActor
    func testOutsidePlanIsGroupedByCategoryLargestFirst() throws {
        let s = try sample()
        for amount in [Decimal(120_000), 300_000, 200_000] { s.expense(amount, on: date(2026, 10, 12), "Kesehatan") }
        s.expense(250_000, on: date(2026, 10, 22), "Hadiah")
        s.expense(70_000, on: date(2026, 10, 3), "Galon")
        s.expense(70_000, on: date(2026, 10, 9), "Galon")
        s.expense(75_000, on: date(2026, 10, 5), nil)
        s.expense(55_000, on: date(2026, 10, 5), "Makan")
        s.expense(90_000, on: date(2026, 9, 28), "Hadiah")
        try s.context.save()

        let look = lookBack(s)
        XCTAssertEqual(look.categoryRows.map(\.name), ["Kesehatan", "Hadiah", "Galon", "Uncategorized"])
        XCTAssertEqual(look.categoryRows.map(\.total), [620_000, 250_000, 140_000, 75_000])
        XCTAssertEqual(look.categoryRows.map(\.count), [3, 1, 2, 1])
        XCTAssertEqual(look.outsideTotal, 1_085_000)
    }

    @MainActor
    func testACategoryAnEnvelopeHereClaimsHasNoAdd() throws {
        let s = try sample()
        s.expense(140_000, on: date(2026, 10, 3), "Galon")
        try s.context.save()
        let row = try XCTUnwrap(lookBack(s).categoryRows.first)
        XCTAssertEqual(row.status, .claimed(envelope: "Kebutuhan Kos di Jkt"))
        XCTAssertFalse(row.canAdd)
        XCTAssertEqual(row.caption, "in Kebutuhan Kos di Jkt here")
    }

    @MainActor
    func testUncategorizedHasNoAdd() throws {
        let s = try sample()
        s.expense(75_000, on: date(2026, 10, 5), nil)
        try s.context.save()
        let row = try XCTUnwrap(lookBack(s).categoryRows.first)
        XCTAssertEqual(row.status, .uncategorized)
        XCTAssertFalse(row.canAdd)
        XCTAssertEqual(row.caption, "categorise them first")
    }

    @MainActor
    func testACategoryAFixedItemUsesHereKeepsAddAndNamesIt() throws {
        let s = try sample()
        s.expense(2_200_000, on: date(2026, 10, 5), "Sewa")
        try s.context.save()
        let row = try XCTUnwrap(lookBack(s).categoryRows.first)
        XCTAssertTrue(row.canAdd)
        XCTAssertEqual(row.caption, "Kos uses Sewa here")
    }

    @MainActor
    func testPaidEarlyIsLeftOutAndCounted() throws {
        let s = try sample()
        let travelling = s.item("Travelling", 2_000_000, kind: .envelope, in: s.november)
        let ticket = s.expense(1_200_000, on: date(2026, 10, 14), "Transport")
        ticket.envelope = travelling
        try s.context.save()
        let look = lookBack(s)
        XCTAssertTrue(look.categoryRows.isEmpty)
        XCTAssertEqual(look.paidEarlyTotal, 1_200_000)
    }

    @MainActor
    func testNoEnvelopeExpensesAreOutsidePlanAndFromPlanOnesAreNot() throws {
        let s = try sample()
        let meal = s.expense(80_000, on: date(2026, 10, 6), "Makan")
        meal.isOutsideEnvelopes = true
        s.expense(40_000, on: date(2026, 10, 6), "Kopi")
        try s.context.save()
        let look = lookBack(s)
        XCTAssertEqual(look.categoryRows.map(\.name), ["Makan"])
        XCTAssertEqual(look.outsideTotal, 80_000)
    }

    @MainActor
    func testACycleWithNoPlanHasEverythingOutside() throws {
        let s = try sample()
        s.expense(1_240_000, on: date(2026, 8, 10), "Makan")
        try s.context.save()
        let look = LookBack.of(cycle(2026, 8), here: s.november, plans: [s.october, s.november],
                               expenses: try s.context.fetch(FetchDescriptor<Expense>()), payday: 1, calendar: calendar)
        XCTAssertFalse(look.hadPlan)
        XCTAssertTrue(look.planRows.isEmpty)
        XCTAssertEqual(look.categoryRows.first?.status, .claimed(envelope: "Hidup"))
        XCTAssertFalse(look.isEmpty)
    }

    @MainActor
    func testNothingMissingIsEmpty() throws {
        let s = Sample(context: try makeInMemoryContext(), october: cycle(2026, 10), november: cycle(2026, 11))
        s.item("Kos", 2_200_000, in: s.october)
        s.item("Kos", 2_200_000, in: s.november)
        try s.context.save()
        XCTAssertTrue(lookBack(s).isEmpty)
    }

    // MARK: - §7 Paging

    func testForwardStopsBeforeTheCycleOnScreen() {
        XCTAssertTrue(LookBack.canGoForward(from: cycle(2026, 9), onScreen: cycle(2026, 11)))
        XCTAssertFalse(LookBack.canGoForward(from: cycle(2026, 10), onScreen: cycle(2026, 11)))
    }

    func testTheTitleCarriesTheYearOnlyAcrossAYear() {
        XCTAssertEqual(LookBackCopy.title(of: cycle(2026, 10), onScreen: cycle(2026, 11), calendar: calendar), "October")
        XCTAssertFalse(LookBackCopy.title(of: cycle(2025, 12), onScreen: cycle(2026, 1), calendar: calendar) == "December")
    }

    // MARK: - §6.5 Display while open

    private struct Row: Identifiable, Equatable {
        let id: LookBackRowID
        let label: String
    }

    @MainActor
    func testAMarkedRowStaysAsItWasAndOthersFollowTheLiveDerivation() throws {
        let s = try sample()
        let kesehatan = LookBackRowID.category(s.categories["Kesehatan"]?.persistentModelID)
        let galon = LookBackRowID.category(s.categories["Galon"]?.persistentModelID)
        let uncategorized = LookBackRowID.category(nil)
        let snapshot = [Row(id: kesehatan, label: "Kesehatan +"), Row(id: galon, label: "Galon +"),
                        Row(id: uncategorized, label: "Uncategorized")]
        let live = [Row(id: galon, label: "Galon in Kesehatan here")]

        let shown = LookBackDisplay.rows(snapshot: snapshot, live: live, marked: [kesehatan])

        XCTAssertEqual(shown.map(\.label), ["Kesehatan +", "Galon in Kesehatan here"])
    }

    // MARK: - §6 Writes

    @MainActor
    func testACopyIsCarryOversCopyClearOfProgress() throws {
        let s = try sample()
        let service = try XCTUnwrap(s.items["Service motor@\(s.october.cycleStart)"])
        service.dueDay = 20
        service.isFunded = true
        guard case .copied(let copy) = LookBackWrites.copy(service, into: s.november, in: s.context) else {
            return XCTFail("expected a copy")
        }
        XCTAssertEqual(copy.plan?.persistentModelID, s.november.persistentModelID)
        XCTAssertEqual(copy.amount, 450_000)
        XCTAssertEqual(copy.dueDay, 20)
        XCTAssertEqual(copy.category?.name, "Transport")
        XCTAssertFalse(copy.isDone)
        XCTAssertFalse(copy.isFunded)
        XCTAssertFalse(copy.carriedOver)
        XCTAssertFalse(lookBack(s).planRows.contains { $0.source.name == "Service motor" })
    }

    @MainActor
    func testACopiedEnvelopeLeavesClaimedCategoriesWhereTheyAre() throws {
        let s = try sample()
        let jajan = try XCTUnwrap(s.items["Jajan@\(s.october.cycleStart)"])
        guard case .copied(let copy) = LookBackWrites.copy(jajan, into: s.november, in: s.context) else {
            return XCTFail("expected a copy")
        }
        XCTAssertEqual(copy.envelopeCategories?.map(\.name), ["Kopi"])
        let hidup = try XCTUnwrap(s.items["Hidup@\(s.november.cycleStart)"])
        XCTAssertEqual(Set(hidup.envelopeCategories?.map(\.name) ?? []), ["Makan", "Bensin"])
    }

    @MainActor
    func testACopiedRpZeroRowIsNotDormant() throws {
        let s = try sample()
        let stnk = try XCTUnwrap(s.items["Perpanjang STNK@\(s.october.cycleStart)"])
        guard case .copied(let copy) = LookBackWrites.copy(stnk, into: s.november, in: s.context) else {
            return XCTFail("expected a copy")
        }
        XCTAssertFalse(PlanDormancy.isDormant(copy))
    }

    @MainActor
    func testWakeGivesTheAmountAndUndoTakesItBack() throws {
        let s = try sample()
        let dormant = try XCTUnwrap(s.items["Beli kado@\(s.november.cycleStart)"])
        let mark = LookBackWrites.wake(dormant, to: 300_000, in: s.context)
        XCTAssertFalse(PlanDormancy.isDormant(dormant))
        XCTAssertEqual(mark.caption(planMonth: "November"), "woken in November")
        LookBackWrites.undo(mark, in: s.context)
        XCTAssertTrue(PlanDormancy.isDormant(dormant))
    }

    @MainActor
    func testANewEnvelopeFromACategoryIsNamedAndSizedByIt() throws {
        let s = try sample()
        let kesehatan = try XCTUnwrap(s.categories["Kesehatan"])
        guard case .newEnvelope(let envelope) = LookBackWrites.newItem(.envelope, for: kesehatan, amount: 620_000,
                                                                       in: s.november, context: s.context) else {
            return XCTFail("expected an envelope")
        }
        XCTAssertEqual(envelope.name, "Kesehatan")
        XCTAssertEqual(envelope.amount, 620_000)
        XCTAssertEqual(envelope.envelopeCategories?.map(\.name), ["Kesehatan"])
        XCTAssertNil(envelope.account)
    }

    @MainActor
    func testANewFixedItemFromACategoryCarriesIt() throws {
        let s = try sample()
        let hadiah = try XCTUnwrap(s.categories["Hadiah"])
        guard case .newFixed(let item) = LookBackWrites.newItem(.fixed, for: hadiah, amount: 250_000,
                                                               in: s.november, context: s.context) else {
            return XCTFail("expected a fixed item")
        }
        XCTAssertEqual(item.category?.name, "Hadiah")
        XCTAssertEqual(item.kind, .fixed)
    }

    @MainActor
    func testAddingToAnEnvelopeAndUndoing() throws {
        let s = try sample()
        let kesehatan = try XCTUnwrap(s.categories["Kesehatan"])
        let hidup = try XCTUnwrap(s.items["Hidup@\(s.november.cycleStart)"])
        let mark = LookBackWrites.add(kesehatan, to: hidup, in: s.context)
        XCTAssertTrue(hidup.envelopeCategories?.contains { $0.name == "Kesehatan" } ?? false)
        XCTAssertEqual(hidup.amount, 938_300)
        XCTAssertEqual(mark.caption(planMonth: "November"), "added to Hidup")
        LookBackWrites.undo(mark, in: s.context)
        XCTAssertFalse(hidup.envelopeCategories?.contains { $0.name == "Kesehatan" } ?? true)
    }

    @MainActor
    func testUndoingACopyDeletesIt() throws {
        let s = try sample()
        let service = try XCTUnwrap(s.items["Service motor@\(s.october.cycleStart)"])
        let mark = LookBackWrites.copy(service, into: s.november, in: s.context)
        LookBackWrites.undo(mark, in: s.context)
        XCTAssertFalse((s.november.items ?? []).contains { $0.name == "Service motor" })
    }

    // MARK: - Copy

    func testStaysInGroupsByEnvelope() {
        XCTAssertEqual(LookBackCopy.staysIn([("Hidup", ["Makan", "Kopi"])]), "Makan, Kopi stay in Hidup")
        XCTAssertEqual(LookBackCopy.staysIn([("Hidup", ["Makan"]), ("Jajan", ["Kopi"])]),
                       "Makan stays in Hidup · Kopi in Jajan")
    }

    func testFixedUseNamesTheFirstAndCountsTheRest() {
        XCTAssertEqual(LookBackCopy.fixedUse(["Netflix", "Vidio", "Apple Service"], category: "Hiburan"),
                       "Netflix and 2 more use Hiburan here")
    }
}
