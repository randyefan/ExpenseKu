//
//  PlanCopyTests.swift
//  ExpenseKuTests
//
//  The small derived pieces the Plan lens renders but that are not money arithmetic:
//  the header's labelled pair, the section title, the check control's five states, the
//  review notice, and the two confirmation bodies.
//
//  The confirmations earn a test because each is a promise about what a destructive
//  button is about to do. "The Rp 4.750.000 expense it created on 20 October stays in
//  your ledger" is the difference between an informed tap and a surprise.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PlanCopyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    // MARK: - CycleHeadline

    /// The header keeps its shape and swaps what it names, so no figure ever changes
    /// meaning silently (§6.2).
    func testTheHeadlineAlwaysNamesItsNumber() {
        XCTAssertEqual(CycleHeadline.spending(220_000).label, "Spending")
        XCTAssertEqual(CycleHeadline.sisa(2_000_000).label, "Sisa")
        XCTAssertEqual(CycleHeadline.sisa(2_000_000).amount, 2_000_000)
    }

    /// Spending is never tinted negative however large it is — it is not an alarm.
    func testSpendingIsAlwaysNeutral() {
        XCTAssertEqual(CycleHeadline.spending(99_000_000).tint, .neutral)
    }

    /// A plan past its income turns the figure red (frame I6).
    func testOnlyANegativeSisaGoesRed() {
        XCTAssertEqual(CycleHeadline.sisa(1).tint, .neutral)
        XCTAssertEqual(CycleHeadline.sisa(0).tint, .neutral)
        XCTAssertEqual(CycleHeadline.sisa(-1_480_000).tint, .negative)
    }

    // MARK: - Section title

    func testSectionTitleCountsItems() {
        XCTAssertEqual(PlanCopy.sectionTitle(itemCount: 14, doneCount: 3), "Plan · 14 items")
        XCTAssertEqual(PlanCopy.sectionTitle(itemCount: 1, doneCount: 1), "Plan · 1 item")
    }

    /// G1, the morning a cycle opens: nothing has been ticked yet, and the header
    /// says so rather than leaving the owner to count.
    func testSectionTitleCallsOutAFreshPlan() {
        XCTAssertEqual(PlanCopy.sectionTitle(itemCount: 16, doneCount: 0),
                       "Plan · 16 items · none done yet")
    }

    /// An empty plan does not claim none are done — there are none at all.
    func testAnEmptyPlanTitleSaysNothingExtra() {
        XCTAssertEqual(PlanCopy.sectionTitle(itemCount: 0, doneCount: 0), "Plan · 0 items")
    }

    // MARK: - DoneCheck

    /// Five states, one of them at a time, derived rather than read as five booleans.
    @MainActor
    func testTheCheckControlHasOneStateAtATime() throws {
        let context = try makeInMemoryContext()
        let todo = PlanItem(name: "Kos", amount: 1)
        let auto = PlanItem(name: "Netflix", amount: 1, dueDay: 2, isAuto: true)
        let envelope = PlanItem(name: "Hidup", amount: 1, kind: .envelope)
        [todo, auto, envelope].forEach(context.insert)
        XCTAssertEqual(DoneCheckState.state(for: todo), .todo)
        XCTAssertEqual(DoneCheckState.state(for: auto), .auto)
        XCTAssertEqual(DoneCheckState.state(for: envelope), .envelope)

        context.insert(Expense(amount: 1, planItem: todo))
        context.insert(Expense(amount: 1, planItem: auto))
        try context.save()
        XCTAssertEqual(DoneCheckState.state(for: todo), .done)
        XCTAssertEqual(DoneCheckState.state(for: auto), .autoPosted)
    }

    /// An envelope's control is inert: it has no transaction to complete. So is an
    /// Auto item that has not fired — there is nothing to confirm yet.
    func testOnlySomeStatesAreTappable() {
        XCTAssertTrue(DoneCheckState.todo.isActionable)
        XCTAssertTrue(DoneCheckState.done.isActionable)
        XCTAssertTrue(DoneCheckState.autoPosted.isActionable)
        XCTAssertFalse(DoneCheckState.auto.isActionable)
        XCTAssertFalse(DoneCheckState.envelope.isActionable)
    }

    // MARK: - Review notice

    /// Only Auto expenses still flagged reach the notice, largest first.
    @MainActor
    func testTheReviewNoticeListsOnlyUnreviewedAutoExpenses() throws {
        let context = try makeInMemoryContext()
        let posted = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, isAuto: true)
        let cleared = PlanItem(name: "Netflix", amount: 130_000, isAuto: true)
        let manual = PlanItem(name: "Kos", amount: 2_200_000)
        [posted, cleared, manual].forEach(context.insert)
        context.insert(Expense(amount: 7_706_000, planItem: posted, needsReview: true))
        context.insert(Expense(amount: 130_000, planItem: cleared, needsReview: false))
        context.insert(Expense(amount: 2_200_000, planItem: manual))
        try context.save()

        let review = ReviewState(cycleItems: [posted, cleared, manual])
        XCTAssertEqual(review.lines.map(\.name), ["Cicilan Rumah BNI"])
        XCTAssertEqual(review.postedCount, 1)
    }

    /// A line says whether the amount matched the plan — the whole reason the notice
    /// opens rather than merely dismissing (decision 21).
    @MainActor
    func testAReviewLineReportsDriftFromThePlan() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Cicil ke Kartu Kredit", amount: 4_700_000, isAuto: true)
        context.insert(item)
        context.insert(Expense(amount: 6_751_000, planItem: item, needsReview: true))
        try context.save()

        let line = try XCTUnwrap(ReviewState(cycleItems: [item]).lines.first)
        XCTAssertFalse(line.matchesPlan)
        XCTAssertEqual(line.planned, 4_700_000)
        XCTAssertEqual(line.actual, 6_751_000)
    }

    /// "while you were away" is a lie when one item fired this morning, so the copy
    /// changes with the burst.
    @MainActor
    func testTheNoticeCopyChangesWithTheCount() throws {
        let context = try makeInMemoryContext()
        func flagged(_ name: String) -> PlanItem {
            let item = PlanItem(name: name, amount: 1, isAuto: true)
            context.insert(item)
            context.insert(Expense(amount: 1, planItem: item, needsReview: true))
            return item
        }
        let one = ReviewState(cycleItems: [flagged("a")])
        XCTAssertEqual(one.title, "1 Auto item posted")
        XCTAssertTrue(one.detail.contains("the amount"))

        let five = ReviewState(cycleItems: (1...5).map { flagged("item \($0)") })
        XCTAssertEqual(five.title, "5 Auto items posted")
        XCTAssertTrue(five.detail.contains("while you were away"))
    }

    @MainActor
    func testNoFlaggedExpensesMeansNoNotice() throws {
        XCTAssertTrue(ReviewState(cycleItems: []).isEmpty)
    }

    // MARK: - Confirmations and notices

    /// I4 names the amount and date before deleting an expense from the ledger.
    func testTheUntickConfirmationNamesWhatItDeletes() {
        let body = PlanCopy.untickBody(amount: 2_200_000, date: date(2026, 10, 5))
        XCTAssertTrue(body.contains("5 October"), body)
        XCTAssertTrue(body.contains("removes it from the ledger"), body)
    }

    /// I7 says the opposite, and must: deleting a plan item leaves its expense alone.
    func testTheDeleteConfirmationPromisesTheExpenseSurvives() {
        let body = PlanCopy.deleteItemBody(amount: 4_750_000, date: date(2026, 10, 20))
        XCTAssertTrue(body.contains("20 October"), body)
        XCTAssertTrue(body.contains("stays in your ledger"), body)
    }

    /// An item that never posted has no expense to reassure anyone about.
    func testDeletingAnUnpostedItemSaysSoPlainly() {
        let body = PlanCopy.deleteItemBody(amount: nil, date: nil)
        XCTAssertTrue(body.contains("nothing in your ledger changes"), body)
    }

    /// E5 names the source cycle by the month it *ended* in, matching the header.
    func testTheCarryOverNoticeNamesTheSourceCycle() {
        let text = PlanCopy.carriedOver(from: date(2026, 9, 1), payday: 1,
                                        items: 6, incomeLines: 2, calendar: calendar)
        XCTAssertTrue(text.contains("Copied from September 2026"), text)
        XCTAssertTrue(text.contains("6 items"), text)
        XCTAssertTrue(text.contains("2 income lines"), text)
    }
}
