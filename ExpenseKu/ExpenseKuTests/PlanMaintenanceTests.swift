//
//  PlanMaintenanceTests.swift
//  ExpenseKuTests
//
//  Auto materialisation and the repairs that keep it safe (ADR-0007).
//
//  Two of these matter more than the rest. The app writes to the ledger here without
//  asking, so "fires exactly once" has to hold across relaunches and across devices;
//  and the fold that cleans up after two devices must never touch an expense the owner
//  confirmed by hand.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanMaintenanceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    /// A September plan on payday 1, with `now` at the 20th.
    @MainActor
    private func makePlan(in context: ModelContext) -> CyclePlan {
        let cycle = PayCycle.containing(date(2026, 9, 10), payday: 1, calendar: calendar)
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        return plan
    }

    @MainActor
    private func run(_ context: ModelContext, now: Date? = nil) {
        PlanMaintenance.run(in: context, now: now ?? date(2026, 9, 20),
                            payday: 1, calendar: calendar)
    }

    // MARK: - Materialisation

    /// An Auto item past its due day writes its Expense, carrying everything the plan
    /// item knows — including its name as the note, without which the ledger shows
    /// several rows reading only "Cicilan".
    @MainActor
    func testAnOverdueAutoItemWritesItsExpense() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        let cicilan = Category(name: "Cicilan")
        let bni = Account(name: "BNI")
        context.insert(cicilan)
        context.insert(bni)
        let item = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 5,
                            isAuto: true, plan: plan, category: cicilan, account: bni)
        context.insert(item)
        try context.save()

        run(context)

        let expense = try XCTUnwrap(item.linkedExpense)
        XCTAssertEqual(expense.amount, 7_706_000, "the planned figure — the one that may be wrong")
        XCTAssertEqual(expense.note, "Cicilan Rumah BNI")
        XCTAssertEqual(expense.category?.name, "Cicilan")
        XCTAssertEqual(expense.account?.name, "BNI")
        XCTAssertTrue(expense.needsReview)
        XCTAssertTrue(item.isDone)
    }

    /// **It fires exactly once.** The link is the guard, so a second launch — or a
    /// third — writes nothing.
    @MainActor
    func testRunningAgainWritesNothing() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        context.insert(PlanItem(name: "Netflix", amount: 130_000, dueDay: 2,
                                isAuto: true, plan: plan))
        try context.save()

        run(context); run(context); run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 1)
    }

    /// Before the due day, nothing happens.
    @MainActor
    func testAnItemNotYetDueDoesNotFire() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        context.insert(PlanItem(name: "Cicil ke Kartu Kredit", amount: 4_700_000,
                                dueDay: 25, isAuto: true, plan: plan))
        try context.save()

        run(context)   // now = 20 September
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 0)
    }

    /// **An Auto item without a due day never fires** (frame I8). The switch is inert
    /// in the editor for exactly this reason.
    @MainActor
    func testAutoWithoutADueDayNeverFires() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        context.insert(PlanItem(name: "Gym membership", amount: 300_000,
                                isAuto: true, plan: plan))
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 0)
    }

    /// A manual item is never materialised, however overdue: it waits for the
    /// confirmation sheet, because a planned figure is not a real one (§7.3).
    @MainActor
    func testAManualItemIsNeverMaterialised() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, dueDay: 5, plan: plan))
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 0)
    }

    /// An envelope never creates an expense at all, Auto or not.
    @MainActor
    func testAnEnvelopeNeverMaterialises() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                dueDay: 5, isAuto: true, plan: plan)
        context.insert(envelope)
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 0)
    }

    /// Five days away produces five expenses on the next launch, in one pass —
    /// materialisation is lazy, not scheduled, and the review notice is written for
    /// exactly this burst.
    @MainActor
    func testFiveOverdueItemsAllLandAtOnce() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        for (index, name) in ["Cicilan", "Kartu Kredit", "Netflix", "Apple", "Vidio"].enumerated() {
            context.insert(PlanItem(name: name, amount: Decimal(100_000 * (index + 1)),
                                    dueDay: index + 1, isAuto: true, plan: plan))
        }
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 5)
        let review = ReviewState(cycleItems: plan.items ?? [])
        XCTAssertEqual(review.postedCount, 5)
        XCTAssertTrue(review.detail.contains("while you were away"))
    }

    /// A plan for a cycle that has not started has nothing due — and that is the
    /// common case, since next cycle's plan is built before payday.
    @MainActor
    func testAFutureCycleFiresNothing() throws {
        let context = try makeInMemoryContext()
        let october = PayCycle.containing(date(2026, 10, 10), payday: 1, calendar: calendar)
        let plan = CyclePlan(cycleStart: october.start)
        context.insert(plan)
        context.insert(PlanItem(name: "Netflix", amount: 130_000, dueDay: 2,
                                isAuto: true, plan: plan))
        try context.save()

        run(context)   // now = 20 September
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 0)
    }

    // MARK: - Repair

    /// Two devices that both fire before they sync leave two linked expenses. The next
    /// pass folds them to one.
    @MainActor
    func testTwinAutoExpensesAreFolded() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        let item = PlanItem(name: "Netflix", amount: 130_000, dueDay: 2,
                            isAuto: true, plan: plan)
        context.insert(item)
        context.insert(Expense(amount: 130_000, date: date(2026, 9, 2),
                               planItem: item, needsReview: true))
        context.insert(Expense(amount: 130_000, date: date(2026, 9, 2),
                               planItem: item, needsReview: true))
        try context.save()
        XCTAssertEqual(item.linkedExpenses?.count, 2)

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 1)
    }

    /// **An expense the owner confirmed is never folded.** The rule only removes an
    /// unreviewed automatic write, which by construction the app wrote itself.
    @MainActor
    func testAConfirmedExpenseSurvivesTheFold() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        let item = PlanItem(name: "Kos", amount: 2_200_000, dueDay: 5, plan: plan)
        context.insert(item)
        context.insert(Expense(amount: 2_200_000, date: date(2026, 9, 5), planItem: item))
        context.insert(Expense(amount: 2_500_000, date: date(2026, 9, 6), planItem: item))
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 2,
                       "neither was written automatically, so neither may be deleted")
    }

    /// Two plans for one cycle collapse into the fuller one, and the loser's contents
    /// move onto the survivor rather than being destroyed.
    ///
    /// The two are deliberately different sizes. Equal ones fall through to a
    /// persistent-ID tiebreak that is best-effort by design — the same caveat
    /// `Person.canonicalMe` documents — so a fixture that ties would be testing which
    /// way a coin landed.
    @MainActor
    func testTwinPlansAreFolded() throws {
        let context = try makeInMemoryContext()
        let start = PayCycle.containing(date(2026, 9, 10), payday: 1, calendar: calendar).start
        let fuller = CyclePlan(cycleStart: start)
        let thinner = CyclePlan(cycleStart: start)
        context.insert(fuller)
        context.insert(thinner)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: fuller))
        context.insert(PlanItem(name: "Netflix", amount: 130_000, plan: fuller))
        context.insert(PlanItem(name: "Vidio", amount: 49_000, plan: fuller))
        context.insert(PlanItem(name: "Listrik", amount: 200_000, plan: thinner))
        context.insert(IncomeLine(name: "Gaji", amount: 20_000_000, plan: thinner))
        try context.save()

        run(context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CyclePlan>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 4,
                       "the loser's item moved across, it was not deleted")
        XCTAssertEqual(fuller.items?.count, 4)
        XCTAssertEqual(fuller.incomeLines?.count, 1)
    }

    /// A launch with nothing to do writes nothing, so it cannot start a sync storm
    /// from the remote-change handler it also runs in.
    @MainActor
    func testAQuietRunMakesNoChanges() throws {
        let context = try makeInMemoryContext()
        let plan = makePlan(in: context)
        context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: plan))
        try context.save()

        run(context)
        XCTAssertFalse(context.hasChanges)
    }
}
