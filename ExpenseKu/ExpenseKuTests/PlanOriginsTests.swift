//
//  PlanOriginsTests.swift
//  ExpenseKuTests
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanOriginsTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func origins(_ plans: [CyclePlan]) -> PlanOrigins {
        PlanOrigins(plans: plans, payday: 1, calendar: calendar)
    }

    @MainActor
    func testAnExpenseAFixedItemCreatedIsFromPlan() throws {
        let context = try makeInMemoryContext()
        let kos = PlanItem(name: "Kos", amount: 2_500_000)
        context.insert(kos)
        let expense = Expense(amount: 2_500_000, date: date(2026, 8, 1), planItem: kos)
        context.insert(expense)
        try context.save()

        XCTAssertEqual(origins([]).origin(of: expense), .fixed)
    }

    @MainActor
    func testAnExpenseInAnEnvelopeCategoryCarriesTheEnvelopeName() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let plan = CyclePlan(cycleStart: date(2026, 8, 1))
        context.insert(plan)
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: plan, envelopeCategories: [makan]))
        let expense = Expense(amount: 45_000, date: date(2026, 8, 5), category: makan)
        context.insert(expense)
        try context.save()

        XCTAssertEqual(origins([plan]).origin(of: expense), .envelope(name: "Hidup"))
    }

    @MainActor
    func testTheEnvelopeIsLookedUpInTheExpensesOwnCycle() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let august = CyclePlan(cycleStart: date(2026, 8, 1))
        context.insert(august)
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: august, envelopeCategories: [makan]))
        let beforePlans = Expense(amount: 35_000, date: date(2025, 12, 18), category: makan)
        context.insert(beforePlans)
        try context.save()

        XCTAssertNil(origins([august]).origin(of: beforePlans))
    }

    @MainActor
    func testADormantEnvelopeClaimsNothing() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let plan = CyclePlan(cycleStart: date(2026, 8, 1))
        context.insert(plan)
        context.insert(PlanItem(name: "Hidup", amount: 0, kind: .envelope, carriedOver: true,
                                plan: plan, envelopeCategories: [makan]))
        let expense = Expense(amount: 45_000, date: date(2026, 8, 5), category: makan)
        context.insert(expense)
        try context.save()

        XCTAssertNil(origins([plan]).origin(of: expense))
    }

    @MainActor
    func testSplitSeparatesOutsidePlanFromPlan() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let kopi = Category(name: "Kopi")
        [makan, kopi].forEach(context.insert)
        let plan = CyclePlan(cycleStart: date(2026, 8, 1))
        context.insert(plan)
        let kos = PlanItem(name: "Kos", amount: 2_500_000, plan: plan)
        context.insert(kos)
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: plan, envelopeCategories: [makan]))
        let expenses = [
            Expense(amount: 2_500_000, date: date(2026, 8, 1), planItem: kos),
            Expense(amount: 165_000, date: date(2026, 8, 2), category: makan),
            Expense(amount: 25_000, date: date(2026, 8, 2), category: kopi),
            Expense(amount: 30_000, date: date(2026, 8, 6)),
        ]
        expenses.forEach(context.insert)
        try context.save()

        let cycle = PayCycle.containing(date(2026, 8, 10), payday: 1, calendar: calendar)
        let split = origins([plan]).split(expenses, in: cycle)
        XCTAssertEqual(split.fromPlan, 2_665_000)
        XCTAssertEqual(split.outsidePlan, 55_000)
        XCTAssertEqual(split.total, 2_720_000)
    }

    func testOutsideFractionIsZeroWhenNothingIsSpent() {
        XCTAssertEqual(SpendingSplit().outsideFraction, 0)
    }
}
