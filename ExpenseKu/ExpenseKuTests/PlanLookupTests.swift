//
//  PlanLookupTests.swift
//  ExpenseKuTests
//
//  Finding a cycle's plan, including the case the PRD does not cover: the owner
//  changes their Monthly Start Date, every stored cycleStart stops equalling any
//  current cycle.start, and without a fallback every plan they ever built vanishes.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PlanLookupTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int, _ d: Int, payday: Int = 1) -> PayCycle {
        PayCycle.containing(date(y, m, d), payday: payday, calendar: calendar)
    }

    /// The ordinary case: an exact start match.
    @MainActor
    func testAnExactMatchWins() throws {
        let context = try makeInMemoryContext()
        let september = cycle(2026, 9, 10)
        let plan = CyclePlan(cycleStart: september.start)
        let other = CyclePlan(cycleStart: date(2026, 8, 1))
        [plan, other].forEach(context.insert)
        try context.save()

        XCTAssertTrue(PlanLookup.plan(for: september, in: [other, plan]) === plan)
    }

    /// **After a payday change** no stored start matches any cycle start. A plan whose
    /// start falls inside the cycle is adopted instead, so the owner's plans re-home
    /// onto the new anchor rather than disappearing.
    @MainActor
    func testAPlanIsAdoptedAfterThePaydayAnchorMoves() throws {
        let context = try makeInMemoryContext()
        // Built on payday 1: the plan is anchored to 1 September.
        let plan = CyclePlan(cycleStart: date(2026, 9, 1))
        context.insert(plan)
        try context.save()

        // The owner moves payday to 25. The cycle 25 Aug → 25 Sep contains 1 Sep.
        let moved = cycle(2026, 9, 10, payday: 25)
        XCTAssertFalse(moved.start == plan.cycleStart)
        XCTAssertTrue(PlanLookup.plan(for: moved, in: [plan]) === plan)
    }

    /// A cycle with nothing in or near it has no plan, and says so.
    @MainActor
    func testNoPlanIsNil() throws {
        let context = try makeInMemoryContext()
        let plan = CyclePlan(cycleStart: date(2026, 9, 1))
        context.insert(plan)
        try context.save()
        XCTAssertNil(PlanLookup.plan(for: cycle(2026, 12, 10), in: [plan]))
    }

    /// Carry-over copies from the most recent earlier plan, skipping gaps — paging two
    /// cycles ahead must still find September rather than nothing.
    @MainActor
    func testSourceSkipsGaps() throws {
        let context = try makeInMemoryContext()
        let july = CyclePlan(cycleStart: date(2026, 7, 1))
        let september = CyclePlan(cycleStart: date(2026, 9, 1))
        [july, september].forEach(context.insert)
        try context.save()

        let november = cycle(2026, 11, 10)
        XCTAssertTrue(PlanLookup.source(before: november, in: [july, september]) === september)
    }

    /// A plan's own cycle is not its carry-over source.
    @MainActor
    func testSourceExcludesTheCycleItself() throws {
        let context = try makeInMemoryContext()
        let september = CyclePlan(cycleStart: date(2026, 9, 1))
        context.insert(september)
        try context.save()
        XCTAssertNil(PlanLookup.source(before: cycle(2026, 9, 10), in: [september]))
    }

    /// The oldest start, so a cycle holding only a plan stays reachable by the back
    /// arrow.
    @MainActor
    func testOldestStart() throws {
        let context = try makeInMemoryContext()
        let plans = [CyclePlan(cycleStart: date(2026, 9, 1)),
                     CyclePlan(cycleStart: date(2026, 7, 1))]
        plans.forEach(context.insert)
        try context.save()
        XCTAssertEqual(PlanLookup.oldestStart(in: plans), date(2026, 7, 1))
        XCTAssertNil(PlanLookup.oldestStart(in: []))
    }
}
