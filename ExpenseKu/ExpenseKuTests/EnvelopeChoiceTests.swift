//
//  EnvelopeChoiceTests.swift
//  ExpenseKuTests
//
//  The editor row, its picker, ＋ on an envelope row and the List lens's bulk move
//  (docs/prd/envelope-assignment.md §4.3–4.6), against the PRD's sample plan.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class EnvelopeChoiceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ m: Int, _ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: hour, minute: minute)) ?? .distantPast
    }

    private struct Sample {
        let plan: CyclePlan
        let hidup: PlanItem
        let kos: PlanItem
        let travelling: PlanItem
        let makan: Category
        let parkir: Category
        let expenses: [Expense]
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let makan = Category(name: "Makan")
        let tisu = Category(name: "Tisu")
        let parkir = Category(name: "Parkir")
        [makan, tisu, parkir].forEach(context.insert)
        let plan = CyclePlan(cycleStart: date(9, 25))
        context.insert(plan)
        let hidup = PlanItem(name: "Hidup (Makan, bensin, emoney saldo)", amount: 938_300, kind: .envelope,
                             plan: plan, envelopeCategories: [makan])
        let kos = PlanItem(name: "Kebutuhan Kos di Jkt (Tisu, sabun, galon)", amount: 193_900, kind: .envelope,
                           plan: plan, envelopeCategories: [tisu])
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: plan)
        let fixed = PlanItem(name: "Kos", amount: 2_200_000, plan: plan)
        [hidup, kos, travelling, fixed].forEach(context.insert)
        let expenses = [Expense(amount: 711_400, date: date(9, 28), category: makan),
                        Expense(amount: 242_200, date: date(9, 28), category: tisu),
                        Expense(amount: 685_000, date: date(10, 12), category: makan)]
        expenses.forEach(context.insert)
        EnvelopeChoice.envelope(travelling.persistentModelID).apply(to: expenses[2], envelopes: [travelling])
        try context.save()
        return Sample(plan: plan, hidup: hidup, kos: kos, travelling: travelling,
                      makan: makan, parkir: parkir, expenses: expenses)
    }

    // MARK: - §4.3 The row

    @MainActor
    func testTheRowIsHiddenWithoutAnActiveEnvelope() throws {
        let context = try makeInMemoryContext()
        let plan = CyclePlan(cycleStart: date(9, 25))
        context.insert(plan)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: plan))
        context.insert(PlanItem(name: "Liburan Saving", amount: 0, kind: .envelope, carriedOver: true, plan: plan))
        try context.save()

        XCTAssertTrue(EnvelopeOptions(plan: plan, cycleExpenses: []).isEmpty, "a Fixed item and a dormant envelope offer nothing")
        XCTAssertTrue(EnvelopeOptions(plan: nil, cycleExpenses: []).isEmpty)
    }

    @MainActor
    func testTheRowNamesWhereTheExpenseLands() throws {
        let s = try sample(in: try makeInMemoryContext())
        let options = EnvelopeOptions(plan: s.plan, cycleExpenses: s.expenses)

        XCTAssertEqual(options.value(for: .byCategory, category: s.makan),
                       EnvelopeRowValue(name: "Hidup (Makan, bensin, emoney saldo)", suffix: "· by category", isChosen: false))
        XCTAssertEqual(options.value(for: .byCategory, category: s.parkir), EnvelopeRowValue(name: "None", isChosen: false))
        XCTAssertEqual(options.value(for: .byCategory, category: nil), EnvelopeRowValue(name: "None", isChosen: false))
        XCTAssertEqual(options.value(for: .noEnvelope, category: s.makan), EnvelopeRowValue(name: "No envelope", isChosen: true))
        XCTAssertEqual(options.value(for: .envelope(s.travelling.persistentModelID), category: s.makan),
                       EnvelopeRowValue(name: "Travelling", isChosen: true))
    }

    // MARK: - §4.4 The picker

    @MainActor
    func testThePickerListsActiveEnvelopesByAmountWithTheirRemainder() throws {
        let s = try sample(in: try makeInMemoryContext())
        let options = EnvelopeOptions(plan: s.plan, cycleExpenses: s.expenses)

        XCTAssertEqual(options.envelopes.map(\.name),
                       ["Travelling", "Hidup (Makan, bensin, emoney saldo)", "Kebutuhan Kos di Jkt (Tisu, sabun, galon)"])
        XCTAssertEqual(options.envelopes.map { options.progress(of: $0)?.remainderText },
                       ["Rp\u{00A0}1.315.000 left", "Rp\u{00A0}226.900 left", "Rp\u{00A0}48.300 over"])
        XCTAssertEqual(options.byCategoryDetail(category: s.makan), "Makan counts in Hidup (Makan, bensin, emoney saldo)")
        XCTAssertEqual(options.byCategoryDetail(category: s.parkir), "Outside plan")
        XCTAssertEqual(options.byCategoryDetail(category: nil), "Choose a category first")
    }

    @MainActor
    func testTheChoiceReadsBackFromTheExpense() throws {
        let s = try sample(in: try makeInMemoryContext())
        XCTAssertEqual(EnvelopeChoice.of(s.expenses[0]), .byCategory)
        XCTAssertEqual(EnvelopeChoice.of(s.expenses[2]), .envelope(s.travelling.persistentModelID))

        EnvelopeChoice.noEnvelope.apply(to: s.expenses[2], envelopes: [s.travelling])
        XCTAssertEqual(EnvelopeChoice.of(s.expenses[2]), .noEnvelope)
        XCTAssertNil(s.expenses[2].envelope)

        EnvelopeChoice.byCategory.apply(to: s.expenses[2], envelopes: [])
        XCTAssertFalse(s.expenses[2].isOutsideEnvelopes)
        XCTAssertEqual(EnvelopeChoice.of(s.expenses[2]), .byCategory)
    }

    /// **Changing the date across a cycle resets an assignment**; No envelope and By
    /// category survive, because neither names a plan.
    @MainActor
    func testMovingTheDateToAnotherCycleResetsAnAssignment() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let november = CyclePlan(cycleStart: date(10, 25))
        context.insert(november)
        let novTravelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: november)
        context.insert(novTravelling)
        try context.save()
        let novOptions = EnvelopeOptions(plan: november, cycleExpenses: [])
        let octOptions = EnvelopeOptions(plan: s.plan, cycleExpenses: s.expenses)

        let assigned = EnvelopeChoice.envelope(s.travelling.persistentModelID)
        XCTAssertEqual(assigned.kept(among: octOptions.envelopes), assigned)
        XCTAssertEqual(assigned.kept(among: novOptions.envelopes), .byCategory, "a same-named envelope is not matched")
        XCTAssertEqual(EnvelopeChoice.noEnvelope.kept(among: novOptions.envelopes), .noEnvelope)
        XCTAssertEqual(EnvelopeChoice.noEnvelope.kept(among: []), .noEnvelope)
        XCTAssertEqual(EnvelopeChoice.byCategory.kept(among: []), .byCategory)
    }

    // MARK: - §4.5 ＋ on an envelope row

    func testAddingFromAnEnvelopeDatesTheExpenseInsideTheViewedCycle() {
        let october = PayCycle.containing(date(10, 1), payday: 25, calendar: calendar)
        let now = date(10, 13, hour: 21, minute: 6)

        XCTAssertEqual(EnvelopeAddDate.date(in: october, now: now, calendar: calendar), now)

        let september = october.previous(payday: 25, calendar: calendar)
        XCTAssertEqual(EnvelopeAddDate.date(in: september, now: now, calendar: calendar), date(9, 24, hour: 21, minute: 6))

        let november = october.next(payday: 25, calendar: calendar)
        XCTAssertEqual(EnvelopeAddDate.date(in: november, now: now, calendar: calendar), date(10, 25, hour: 21, minute: 6))
        XCTAssertTrue(november.contains(EnvelopeAddDate.date(in: november, now: now, calendar: calendar)))
    }

    // MARK: - §4.6 Select mode and the bulk move

    @MainActor
    func testSelectAllTakesTheVisibleSelectableRowsAndThenDeselects() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let fixed = try XCTUnwrap(s.plan.items?.first { $0.name == "Kos" })
        let rent = Expense(amount: 2_200_000, date: date(10, 5), planItem: fixed)
        context.insert(rent)
        try context.save()
        let visible = s.expenses + [rent]

        var selection = ExpenseSelection()
        selection.toggle(rent)
        XCTAssertTrue(selection.isEmpty, "a row a Fixed item created is not selectable")

        selection.toggleAll(of: visible)
        XCTAssertEqual(selection.count, 3)
        XCTAssertTrue(selection.isAllSelected(of: visible))

        selection.toggleAll(of: visible)
        XCTAssertTrue(selection.isEmpty, "Select All turns into Deselect All")

        selection.toggle(s.expenses[0])
        selection.toggle(s.expenses[1])
        selection.toggle(s.expenses[1])
        XCTAssertEqual(selection.expenses(in: visible), [s.expenses[0]])
    }

    /// A filter that hides a checked row drops it from the selection.
    @MainActor
    func testAFilterThatHidesARowDropsItFromTheSelection() throws {
        let s = try sample(in: try makeInMemoryContext())
        var selection = ExpenseSelection()
        selection.toggleAll(of: s.expenses)
        selection.keepOnly([s.expenses[0]])
        XCTAssertEqual(selection.count, 1)
        XCTAssertFalse(selection.isAllSelected(of: []))
    }

    @MainActor
    func testTheBulkMoveAppliesToEveryChosenExpenseAtOnce() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let fixed = try XCTUnwrap(s.plan.items?.first { $0.name == "Kos" })
        let rent = Expense(amount: 2_200_000, date: date(10, 5), planItem: fixed)
        context.insert(rent)
        try context.save()
        let options = EnvelopeOptions(plan: s.plan, cycleExpenses: s.expenses)

        EnvelopeChoice.envelope(s.travelling.persistentModelID)
            .apply(to: [s.expenses[0], s.expenses[1], rent], envelopes: options.envelopes)
        XCTAssertEqual(s.expenses[0].envelope, s.travelling)
        XCTAssertEqual(s.expenses[1].envelope, s.travelling)
        XCTAssertNil(rent.envelope)

        EnvelopeChoice.noEnvelope.apply(to: [s.expenses[0]], envelopes: options.envelopes)
        XCTAssertTrue(s.expenses[0].isOutsideEnvelopes)
        XCTAssertNil(s.expenses[0].envelope)
    }
}
