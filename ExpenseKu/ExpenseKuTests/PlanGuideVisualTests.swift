//
//  PlanGuideVisualTests.swift
//  ExpenseKuTests
//
//  docs/prd/plan-guide-visual.md: the spotlight walk of §4.4, the lifetime table of §5 and
//  the content contract of §4.5, checked against the guide's own in-memory sample.
//

import SwiftData
import XCTest
@testable import ExpenseKu

nonisolated final class PlanGuideVisualTests: XCTestCase {
    private func opened(_ material: PlanGuideMaterial, _ progress: PlanGuideProgress = PlanGuideProgress()) -> PlanGuideSession {
        var visit = PlanGuideSession(entry: .menu, progress: progress)
        visit.open(material)
        return visit
    }

    // MARK: - §4.4 Navigation

    func testNextWalksTheSpotlightsBeforeTheStep() {
        var visit = opened(.introduction)
        visit.next()
        XCTAssertEqual(visit.route, .lesson(.introduction, step: 1))
        XCTAssertEqual(visit.spotlight, 2)
    }

    func testNextFromTheLastSpotlightOpensTheNextStepAtSpotlightOne() {
        var visit = opened(.introduction)
        visit.next(); visit.next(); visit.next()
        XCTAssertEqual(visit.route, .lesson(.introduction, step: 2))
        XCTAssertEqual(visit.spotlight, 1)
    }

    func testBackWalksTheSpotlightsBackwards() {
        var visit = opened(.introduction)
        visit.next(); visit.next(); visit.back()
        XCTAssertEqual(visit.spotlight, 2)
    }

    func testBackAcrossStepsLandsOnThePreviousStepsLastSpotlight() {
        var visit = opened(.followEnvelope)
        while case .lesson(_, 1) = visit.route { visit.next() }
        visit.back()
        XCTAssertEqual(visit.route, .lesson(.followEnvelope, step: 1))
        XCTAssertEqual(visit.spotlight, 5)
    }

    func testTopicsShowsOnlyAtStepOneSpotlightOne() {
        var visit = opened(.startPlan)
        XCTAssertTrue(visit.isAtStart)
        visit.next()
        XCTAssertFalse(visit.isAtStart)
    }

    func testFinishShowsOnlyOnTheLastSpotlightOfTheLastStep() {
        var visit = opened(.readAndTidy)
        while case .lesson(_, 1) = visit.route { visit.next() }
        XCTAssertFalse(visit.isAtEnd)
        visit.finish()
        XCTAssertFalse(visit.progress.isRead(.readAndTidy))
        visit.next()
        XCTAssertTrue(visit.isAtEnd)
        visit.finish()
        XCTAssertTrue(visit.progress.isRead(.readAndTidy))
    }

    func testSpotlightsDoNotTouchSavedProgress() {
        var visit = opened(.paydayTransfers)
        let before = visit.progress
        visit.next(); visit.next()
        XCTAssertEqual(visit.progress, before)
    }

    // MARK: - §5 Lifetime

    func testAReopenedStepStartsAtSpotlightOne() {
        var visit = opened(.paydayTransfers)
        while case .lesson(_, 1) = visit.route { visit.next() }
        visit.next(); visit.next()
        visit.showTopics()
        visit.open(.paydayTransfers)
        XCTAssertEqual(visit.route, .lesson(.paydayTransfers, step: 2))
        XCTAssertEqual(visit.spotlight, 1)
    }

    func testStepCountsAndMaterialIdsAreUnchanged() {
        XCTAssertEqual(PlanGuideMaterial.allCases.map(\.stepCount), [3, 2, 2, 2, 2, 2, 2])
        XCTAssertEqual(PlanGuideMaterial.allCases.map(\.rawValue),
                       ["introduction", "startPlan", "allocationTypes", "managePlanItems",
                        "paydayTransfers", "followEnvelope", "readAndTidy"])
    }

    // MARK: - §4.3, §4.5 Content contract

    @MainActor
    func testEveryStepHasTwoToFiveSpotlightsMatchingTheWalk() {
        for material in PlanGuideMaterial.allCases {
            let lessons = PlanGuideContent.lessons(of: material)
            XCTAssertEqual(lessons.map(\.spotlights.count), material.spotlightCounts, "\(material)")
            XCTAssertTrue(lessons.allSatisfy { (2...5).contains($0.spotlights.count) }, "\(material)")
        }
    }

    @MainActor
    func testCaptionsAndLeadsStayShort() {
        for material in PlanGuideMaterial.allCases {
            for lesson in PlanGuideContent.lessons(of: material) {
                XCTAssertLessThanOrEqual(lesson.lead.split(separator: " ").count, 16, lesson.lead)
                for spotlight in lesson.spotlights {
                    XCTAssertLessThanOrEqual(spotlight.caption.split(separator: " ").count, 16, spotlight.caption)
                }
            }
        }
    }

    @MainActor
    func testSnapshotsAccumulateWithinAStepAndBackRestoresTheEarlierState() {
        let fill = PlanGuideContent.lessons(of: .followEnvelope)[0].spotlights
        XCTAssertEqual(fill.map(\.state.harianSpent), [120_000, 120_000, 120_000, 165_000, 1_950_000])
        XCTAssertEqual(fill.map(\.swapsSnapshot), [false, false, false, true, true])
        let partial = PlanGuideContent.lessons(of: .paydayTransfers)[1].spotlights
        XCTAssertEqual(partial.map(\.state.liburanChosen), [false, false, false, false])
        XCTAssertEqual(partial.map(\.state.harianFunded), [false, false, false, true])
    }

    @MainActor
    func testManageStepsWalkKosThroughItsStates() {
        let status = PlanGuideContent.lessons(of: .managePlanItems)[0].spotlights.map(\.state.kos)
        XCTAssertEqual(status, [.planned, .funded, .done])
        let auto = PlanGuideContent.lessons(of: .managePlanItems)[1].spotlights
        XCTAssertEqual(auto.map(\.state.kos), [.planned, .autoPosted, .funded])
        XCTAssertTrue(auto.allSatisfy(\.state.kosIsAuto))
    }

    // MARK: - §4.2 Sample

    @MainActor
    func testBaselineTotalsMatchTheNovemberSample() {
        let totals = PlanGuideSample(.baseline).contents.totals
        XCTAssertEqual(totals.totalIncome, 8_000_000)
        XCTAssertEqual(totals.totalCost, 5_000_000)
        XCTAssertEqual(totals.sisa, 3_000_000)
    }

    @MainActor
    func testTransferChecklistNeedsJagoAndMandiri() {
        let rows = PlanGuideSample(.baseline).contents.transfers
        XCTAssertEqual(rows.map(\.accountName), ["Jago", "Mandiri"])
        XCTAssertEqual(rows.map(\.transfer), [2_800_000, 2_200_000])
    }

    @MainActor
    func testKosWithoutAnAccountDropsMandirisLine() {
        var state = PlanGuideSampleState.baseline
        state.kosHasAccount = false
        XCTAssertEqual(PlanGuideSample(state).contents.transfers.map(\.accountName), ["Jago"])
    }

    @MainActor
    func testEverydaySpendingFillsHarianAndLeavesRemaining() {
        let sample = PlanGuideSample(PlanGuideSampleState(kos: .done, harianSpent: PlanGuideSampleState.harianEveryday))
        let harian = sample.contents.envelope(for: sample.harian)
        XCTAssertEqual(harian?.spent, 120_000)
        XCTAssertEqual(sample.contents.totals.sisa, 3_000_000)
        XCTAssertEqual(DoneCheckState.state(for: sample.kos), .done)
    }

    @MainActor
    func testMarkedMakanAndOverspendingRaiseHarian() {
        let marked = PlanGuideSample(PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianWithMakan))
        XCTAssertEqual(marked.contents.envelope(for: marked.harian)?.spent, 165_000)
        let over = PlanGuideSample(PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianOverspent))
        XCTAssertEqual(over.contents.envelope(for: over.harian)?.spent, 1_950_000)
    }

    @MainActor
    func testPartialTransferMovesHarianAndLeavesJagoHalfFilled() {
        let sample = PlanGuideSample(PlanGuideSampleState(gajiArrived: true, harianFunded: true))
        let jago = sample.contents.transfers.first { $0.accountName == "Jago" }
        XCTAssertEqual(jago?.fill, .partIn)
        XCTAssertEqual(jago?.toGo, 1_000_000)
    }

    @MainActor
    func testDeselectingLiburanDropsTransferNowToHarian() throws {
        let sample = PlanGuideSample(PlanGuideSampleState(gajiArrived: true))
        let jago = try XCTUnwrap(sample.contents.transfers.first { $0.accountName == "Jago" })
        let chosen = Set(jago.members.map(\.id).filter { $0 != sample.liburan.persistentModelID })
        XCTAssertEqual(TransferPick(row: jago, chosen: chosen).transferNow, 1_800_000)
    }

    @MainActor
    func testGrabIsPaidElsewhereAndMovesFromJago() {
        let open = PlanGuideSample(PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianEveryday))
        let row = PaidElsewhere(envelope: open.harian, expenses: open.harianExpenses).rows.first
        XCTAssertEqual(row?.accountName, "CC Danamon")
        XCTAssertEqual(row?.total, 75_000)
        XCTAssertEqual(row?.fill, .nothingIn)
        let moved = PlanGuideSample(PlanGuideSampleState(harianSpent: PlanGuideSampleState.harianEveryday,
                                                         paidElsewhereMoved: true))
        XCTAssertEqual(PaidElsewhere(envelope: moved.harian, expenses: moved.harianExpenses).rows.first?.fill, .allIn)
    }

    @MainActor
    func testGroupSharesAreHousingDailyTravel() {
        let shares = PlanGuideSample(.baseline).contents.groupShares
        XCTAssertEqual(shares.map(\.planned), [2_200_000, 1_800_000, 1_000_000])
        XCTAssertEqual(shares.map { Int(($0.share * 100).rounded()) }, [28, 23, 13])
    }

    @MainActor
    func testAutoPostedKosRaisesTheReviewNotice() {
        let sample = PlanGuideSample(PlanGuideSampleState(gajiArrived: true, kos: .autoPosted, kosIsAuto: true))
        XCTAssertFalse(sample.contents.review.isEmpty)
        XCTAssertEqual(DoneCheckState.state(for: sample.kos), .autoPosted)
    }

    @MainActor
    func testSortByAccountGroupsUnderJagoAndMandiri() {
        let sample = PlanGuideSample(.baseline)
        let sections = PlanSections.sections(sample.contents.activeItems, by: .account,
                                             cycle: sample.cycle, calendar: sample.calendar)
        XCTAssertEqual(sections.compactMap(\.title).map { $0.components(separatedBy: " · ")[0] }, ["Jago", "Mandiri"])
    }

    @MainActor
    func testTheSampleNeverTouchesTheOwnersStore() {
        let sample = PlanGuideSample(.baseline)
        XCTAssertTrue(sample.container.configurations.allSatisfy(\.isStoredInMemoryOnly))
    }
}
