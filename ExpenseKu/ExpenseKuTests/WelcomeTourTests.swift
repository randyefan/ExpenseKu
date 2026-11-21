//
//  WelcomeTourTests.swift
//  ExpenseKuTests
//
//  docs/prd/welcome-tour.md: when the tour opens (§4.1), how a mission completes (§4.3–§4.5),
//  where the guide floats (§4.3), Skip and leaving (§4.7), the lifetime table (§6) and the
//  sample's own figures (§5), on 21 November 2026 as the PRD assumes.
//

import SwiftData
import XCTest
@testable import ExpenseKu

nonisolated final class WelcomeTourTests: XCTestCase {
    private let script = TourScript(lastCycleName: "October")

    // MARK: - §4.1 When the tour opens

    func testOpensOnTheOpeningForANewUser() {
        XCTAssertEqual(TourAutoOpen.entry(outcome: nil, progress: TourProgress(), hasExpenses: false, isEphemeral: false),
                       .opening)
    }

    func testReopensAtTheStartOfAnUnfinishedChapter() {
        let progress = TourProgress().starting(.browse)
        XCTAssertEqual(TourAutoOpen.entry(outcome: nil, progress: progress, hasExpenses: false, isEphemeral: false),
                       .chapter(.browse))
    }

    func testNeverOpensOnceFinishedOrSkipped() {
        for outcome in [TourOutcome.finished, .skipped] {
            XCTAssertNil(TourAutoOpen.entry(outcome: outcome, progress: TourProgress(), hasExpenses: false,
                                            isEphemeral: false))
        }
    }

    func testNeverOpensOnceTheUserHasAnExpense() {
        XCTAssertNil(TourAutoOpen.entry(outcome: nil, progress: TourProgress().starting(.plan), hasExpenses: true,
                                        isEphemeral: false))
    }

    func testNeverOpensOnTheEphemeralStore() {
        XCTAssertNil(TourAutoOpen.entry(outcome: nil, progress: TourProgress(), hasExpenses: false, isEphemeral: true))
    }

    // MARK: - §4.7 Skip and §6 lifetime

    func testSkippingSetsSkippedOnTheFirstRun() {
        XCTAssertEqual(TourAutoOpen.outcome(afterSkipping: nil, isReplay: false), .skipped)
    }

    func testLeavingAReplayKeepsTheEarlierOutcome() {
        XCTAssertEqual(TourAutoOpen.outcome(afterSkipping: .finished, isReplay: true), .finished)
        XCTAssertNil(TourAutoOpen.outcome(afterSkipping: nil, isReplay: true))
    }

    func testFinishingAChapterMarksItDoneAndLeavingForgetsTheStart() {
        let progress = TourProgress().starting(.record).finishing(.record).starting(.browse).leaving()
        XCTAssertEqual(progress.done, [.record])
        XCTAssertNil(progress.started)
        XCTAssertEqual(progress.doneCount, 1)
    }

    // MARK: - §4.5 Missions

    func testChapterOneHasSevenMissionsAndTheReceiptOpensAFreshEditor() {
        let record = script.missions(in: .record)
        XCTAssertEqual(record.count, 7)
        XCTAssertEqual(record[6].beats.first?.command, .openEditor)
        XCTAssertEqual(record[6].beats.first?.target, .readReceipt)
    }

    func testChapterCountsMatchThePRD() {
        XCTAssertEqual(script.missions(in: .browse).count, 3)
        XCTAssertEqual(script.missions(in: .plan).count, 2)
        XCTAssertEqual(script.missions(in: .plan)[1].beats.count, 3)
        XCTAssertEqual(script.missions(in: .insights).count, 3)
    }

    func testKeypadCompletesOnlyAtFortyFiveThousand() {
        let goal = TourGoal.amount(45_000)
        XCTAssertFalse(goal.isMet(by: .amount(31_500)))
        XCTAssertTrue(goal.isMet(by: .amount(45_000)))
    }

    func testPersonGoalIsMetWhenIbuJoinsMe() {
        XCTAssertTrue(TourGoal.person("Ibu").isMet(by: .people(["Me", "Ibu"])))
        XCTAssertFalse(TourGoal.person("Ibu").isMet(by: .people(["Me", "Rina"])))
    }

    func testSearchGoalIgnoresCaseAndSpaces() {
        XCTAssertTrue(TourGoal.search("kopi").isMet(by: .search("Kopi ")))
        XCTAssertFalse(TourGoal.search("kopi").isMet(by: .search("kop")))
    }

    func testCycleGoalTellsLastCycleFromCurrent() {
        XCTAssertTrue(TourGoal.cycle(isCurrent: false).isMet(by: .cycle(isCurrent: false)))
        XCTAssertFalse(TourGoal.cycle(isCurrent: true).isMet(by: .cycle(isCurrent: false)))
    }

    func testStepWalksBeatsThenMissionsThenEndsTheChapter() {
        XCTAssertEqual(script.step(after: TourPosition(chapter: .browse, mission: 0, beat: 0)),
                       .beat(TourPosition(chapter: .browse, mission: 0, beat: 1)))
        XCTAssertEqual(script.step(after: TourPosition(chapter: .browse, mission: 0, beat: 1)),
                       .missionDone(next: TourPosition(chapter: .browse, mission: 1, beat: 0)))
        XCTAssertEqual(script.step(after: TourPosition(chapter: .browse, mission: 2, beat: 1)), .chapterDone)
    }

    func testSegmentsFillPerMissionAndWholeForDoneChapters() {
        let position = TourPosition(chapter: .browse, mission: 1, beat: 0)
        XCTAssertEqual(script.fill(of: .record, at: position, done: [.record]), 1)
        XCTAssertEqual(script.fill(of: .browse, at: position, done: [.record]), 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(script.fill(of: .plan, at: position, done: [.record]), 0)
    }

    func testSpotlightsAreTalkingAndOnlyActsLetTheTargetThrough() {
        let spotlight = script.missions(in: .plan)[1].beats[0]
        XCTAssertEqual(spotlight.pose, .talking)
        XCTAssertFalse(spotlight.letsTargetThrough)
        XCTAssertTrue(script.missions(in: .plan)[0].beats[0].letsTargetThrough)
    }

    func testRemainingSpotlightPointsAtThePlanOptions() {
        XCTAssertEqual(script.missions(in: .plan)[1].beats[2].companion, .planOptions)
    }

    func testResultsStayLitWithoutARing() {
        XCTAssertEqual(script.missions(in: .record)[1].beats[0].readout, .amountReadout)
        XCTAssertEqual(script.missions(in: .browse)[2].beats[1].readout, .searchResults)
    }

    func testCompletionMomentsAreHappy() {
        let moments = TourChapter.allCases.flatMap { script.missions(in: $0) }.flatMap(\.beats)
            .filter { $0.kind == .moment }
        XCTAssertEqual(moments.map(\.target), [.landedRow, .landedRow, .recordedRow, .topRank])
        XCTAssertTrue(moments.allSatisfy { $0.pose == .happy })
    }

    // MARK: - §4.3 Where the guide floats

    private let bounds = CGRect(x: 16, y: 68, width: 370, height: 760)
    private let unit = CGSize(width: 370, height: 140)

    func testGuideSitsBelowATargetNearTheTop() {
        let placement = TourPlacement.place(target: CGRect(x: 286, y: 62, width: 44, height: 44), unit: unit, in: bounds)
        XCTAssertEqual(placement.side, .below)
        XCTAssertGreaterThanOrEqual(placement.origin.y, 106)
    }

    func testGuideSitsAboveATargetNearTheBottom() {
        let keypad = CGRect(x: 0, y: 610, width: 402, height: 260)
        let placement = TourPlacement.place(target: keypad, unit: unit, in: bounds)
        XCTAssertEqual(placement.side, .above)
        XCTAssertLessThanOrEqual(placement.origin.y + unit.height, keypad.minY)
    }

    func testWalletFlipsWhenTheTargetIsOnTheLeft() {
        let right = TourPlacement.place(target: CGRect(x: 330, y: 140, width: 44, height: 44), unit: unit, in: bounds)
        let left = TourPlacement.place(target: CGRect(x: 32, y: 140, width: 44, height: 44), unit: unit, in: bounds)
        XCTAssertTrue(right.walletLeading)
        XCTAssertFalse(right.mirrored)
        XCTAssertFalse(left.walletLeading)
        XCTAssertTrue(left.mirrored)
    }

    func testTailPointsAtThePointerWhenOneIsGiven() {
        let remaining = CGRect(x: 26, y: 230, width: 350, height: 40)
        let options = CGRect(x: 229, y: 62, width: 44, height: 44)
        let placement = TourPlacement.place(target: remaining, pointer: options, unit: unit, in: bounds)
        XCTAssertEqual(placement.tailX ?? 0, options.midX - placement.origin.x, accuracy: 0.5)
    }

    func testNoTargetPutsTheGuideAtTheBottomWithoutATail() {
        let placement = TourPlacement.place(target: nil, unit: unit, in: bounds)
        XCTAssertNil(placement.tailX)
        XCTAssertEqual(placement.origin.y + unit.height, bounds.maxY - 24, accuracy: 0.5)
    }
}

// MARK: - §5 Sample data

nonisolated final class WelcomeTourSampleTests: XCTestCase {
    @MainActor
    private var today: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 12)) ?? .now
    }

    @MainActor
    private func expenses(_ sample: TourSample) -> [Expense] {
        (try? sample.container.mainContext.fetch(FetchDescriptor<Expense>())) ?? []
    }

    @MainActor
    private func total(_ expenses: [Expense]) -> Decimal { expenses.reduce(0) { $0 + $1.amount } }

    @MainActor
    func testCyclesRunFromThe25th() {
        let sample = TourSample(startingAt: .record, today: today)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.day, from: sample.cycle.start), 25)
        XCTAssertEqual(calendar.component(.month, from: sample.cycle.start), 10)
        XCTAssertEqual(calendar.component(.month, from: sample.lastCycle.start), 9)
    }

    @MainActor
    func testThisCycleBeforeChapterOne() {
        let sample = TourSample(startingAt: .record, today: today)
        let thisCycle = expenses(sample).filter { sample.cycle.contains($0.date) }
        XCTAssertEqual(thisCycle.count, 13)
        XCTAssertEqual(total(thisCycle), 3_098_300)
        XCTAssertNil(sample.recordedExpense)
    }

    @MainActor
    func testLastCycleHasEightExpensesAndNoKopi() {
        let sample = TourSample(startingAt: .record, today: today)
        let lastCycle = expenses(sample).filter { sample.lastCycle.contains($0.date) }
        XCTAssertEqual(lastCycle.count, 8)
        XCTAssertEqual(total(lastCycle), 2_871_200)
        XCTAssertFalse(lastCycle.contains { $0.note.localizedStandardContains("kopi") })
    }

    @MainActor
    func testLaterChaptersStartWithChapterOnesTwoExpenses() {
        let sample = TourSample(startingAt: .browse, today: today)
        let thisCycle = expenses(sample).filter { sample.cycle.contains($0.date) }
        XCTAssertEqual(total(thisCycle), 3_175_300)
        XCTAssertEqual(sample.recordedExpense?.amount, 45_000)
        XCTAssertEqual(Set(sample.recordedExpense?.people?.map(\.name) ?? []), ["Me", "Ibu"])
        let receipt = thisCycle.first { $0.amount == 32_000 }
        XCTAssertEqual(receipt?.isReceiptToCheck, true)
    }

    @MainActor
    func testSearchForKopiFindsTwo() {
        let sample = TourSample(startingAt: .browse, today: today)
        let hits = expenses(sample).filter { $0.note.localizedStandardContains("kopi") }
        XCTAssertEqual(hits.count, 2)
        XCTAssertEqual(total(hits), 60_000)
    }

    @MainActor
    func testMakanThisCycleAfterChapterOne() {
        let sample = TourSample(startingAt: .insights, today: today)
        let makan = expenses(sample).filter { sample.cycle.contains($0.date) && $0.category?.name == "Makan" }
        XCTAssertEqual(makan.count, 8)
        XCTAssertEqual(total(makan), 456_500)
        XCTAssertEqual(total(makan.filter { $0.account?.name == "Jago" }), 308_500)
    }

    @MainActor
    func testPlanLeavesFourMillionAndHarianHasSpent649k() {
        let sample = TourSample(startingAt: .plan, today: today)
        let plan = try? sample.container.mainContext.fetch(FetchDescriptor<CyclePlan>()).first
        let thisCycle = expenses(sample).filter { sample.cycle.contains($0.date) }
        let contents = PlanContents(plan: plan, cycle: sample.cycle, cycleExpenses: thisCycle, calendar: .current)
        XCTAssertEqual(contents.totals.sisa, 4_000_000)
        let harian = plan?.items?.first { $0.name == "Harian" }
        XCTAssertEqual(harian.flatMap(contents.envelope(for:))?.spent, 649_000)
    }

    @MainActor
    func testIbuRanksFirstOnTheAllTimeLeaderboard() {
        let sample = TourSample(startingAt: .insights, today: today)
        let ranked = PeopleLeaderboard.ranked(from: expenses(sample))
        XCTAssertEqual(ranked.first?.person.name, "Ibu")
        XCTAssertEqual(ranked.first?.total, 814_100)
        XCTAssertEqual(ranked.first?.sharedCount, 8)
        XCTAssertEqual(ranked.dropFirst().first?.person.name, "Rina")
        XCTAssertEqual(ranked.dropFirst().first?.total, 306_500)
    }

    @MainActor
    func testTheSampleNeverTouchesTheMainStore() {
        let sample = TourSample(startingAt: .record, today: today)
        XCTAssertTrue(sample.container.configurations.allSatisfy { $0.isStoredInMemoryOnly })
    }
}
