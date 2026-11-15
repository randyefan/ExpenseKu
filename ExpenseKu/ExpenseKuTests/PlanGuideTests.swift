//
//  PlanGuideTests.swift
//  ExpenseKuTests
//
//  docs/prd/plan-guide.md, one test per rule of §4.1, §4.3, §4.5 and the §6 lifetime table.
//  The guide writes no plan data, so these drive the progress and session alone; the
//  content tests check the lessons against the PRD's November sample (§5).
//

import XCTest
@testable import ExpenseKu

nonisolated final class PlanGuideTests: XCTestCase {
    private func session(_ entry: PlanGuideEntry, _ progress: PlanGuideProgress = PlanGuideProgress()) -> PlanGuideSession {
        PlanGuideSession(entry: entry, progress: progress)
    }

    private func reading(_ material: PlanGuideMaterial, to step: Int, from progress: PlanGuideProgress = PlanGuideProgress()) -> PlanGuideProgress {
        var visit = session(.menu, progress)
        visit.open(material)
        while case .lesson(_, let shown) = visit.route, shown < step { visit.next() }
        return visit.progress
    }

    private func finished(_ material: PlanGuideMaterial, from progress: PlanGuideProgress = PlanGuideProgress()) -> PlanGuideProgress {
        var visit = session(.menu, reading(material, to: material.stepCount, from: progress))
        visit.open(material)
        while case .lesson(_, let shown) = visit.route, shown < material.stepCount { visit.next() }
        visit.finish()
        return visit.progress
    }

    // MARK: - §4.1 Entry points

    func testInvitationOffersViewGuideWithoutAPlanBeforeTheIntroStarts() {
        XCTAssertEqual(PlanGuideInvitation.shown(hasPlan: false, progress: PlanGuideProgress()), .view)
    }

    func testInvitationOffersToContinueAnIntroInProgress() {
        XCTAssertEqual(PlanGuideInvitation.shown(hasPlan: false, progress: reading(.introduction, to: 2)), .resume)
    }

    func testInvitationHidesOnceTheIntroIsComplete() {
        XCTAssertNil(PlanGuideInvitation.shown(hasPlan: false, progress: finished(.introduction)))
    }

    func testInvitationHidesWheneverAPlanExistsEvenUnread() {
        XCTAssertNil(PlanGuideInvitation.shown(hasPlan: true, progress: PlanGuideProgress()))
        XCTAssertNil(PlanGuideInvitation.shown(hasPlan: true, progress: reading(.introduction, to: 2)))
    }

    func testFirstInvitationTapOpensIntroStepOne() {
        XCTAssertEqual(session(.invitation).route, .lesson(.introduction, step: 1))
    }

    func testInvitationResumesTheSavedIntroStep() {
        XCTAssertEqual(session(.invitation, reading(.introduction, to: 2)).route, .lesson(.introduction, step: 2))
    }

    func testMenuAlwaysOpensTheIndexEvenMidLesson() {
        let midway = reading(.paydayTransfers, to: 2)
        XCTAssertEqual(session(.menu, midway).route, .index)
        XCTAssertEqual(session(.menu, reading(.introduction, to: 3)).route, .index)
    }

    // MARK: - §4.2 Introduction

    func testExploreTopicsCompletesOnlyTheIntroAndOpensTheIndex() {
        var visit = session(.invitation)
        visit.next(); visit.next(); visit.finish()
        XCTAssertEqual(visit.route, .index)
        XCTAssertEqual(visit.progress.status(of: .introduction), .read)
        for topic in PlanGuideMaterial.buildTopics + PlanGuideMaterial.useTopics {
            XCTAssertEqual(visit.progress.status(of: topic), .notStarted)
        }
    }

    // MARK: - §4.3 Topic index

    func testEveryMaterialStartsNotStarted() {
        for material in PlanGuideMaterial.allCases {
            XCTAssertEqual(PlanGuideProgress().status(of: material), .notStarted)
        }
    }

    func testTopicsAreOpenWithoutTheIntroOrEarlierTopics() {
        var visit = session(.menu)
        visit.open(.readAndTidy)
        XCTAssertEqual(visit.route, .lesson(.readAndTidy, step: 1))
    }

    func testIndexListsSixTopicsInTwoGroupsInOrder() {
        XCTAssertEqual(PlanGuideMaterial.buildTopics, [.startPlan, .allocationTypes, .managePlanItems])
        XCTAssertEqual(PlanGuideMaterial.useTopics, [.paydayTransfers, .followEnvelope, .readAndTidy])
    }

    func testIncompleteTopicResumesItsLastDisplayedStep() {
        var visit = session(.menu, reading(.managePlanItems, to: 2))
        visit.open(.managePlanItems)
        XCTAssertEqual(visit.route, .lesson(.managePlanItems, step: 2))
        XCTAssertEqual(visit.progress.status(of: .managePlanItems), .inProgress(step: 2, of: 2))
    }

    func testIntroCompletionDoesNotMarkTheLibraryComplete() {
        let progress = finished(.introduction)
        XCTAssertFalse(PlanGuideMaterial.useTopics.contains { progress.isRead($0) })
    }

    // MARK: - §4.5 Lesson navigation and completion

    func testNextAdvancesExactlyOneStep() {
        var visit = session(.invitation)
        visit.next()
        XCTAssertEqual(visit.route, .lesson(.introduction, step: 2))
    }

    func testBackIsRecordedAsTheDisplayedStep() {
        var visit = session(.invitation)
        visit.next(); visit.next(); visit.back()
        XCTAssertEqual(visit.progress.status(of: .introduction), .inProgress(step: 2, of: 3))
    }

    func testTopicsReturnsToIndexWithoutCompleting() {
        var visit = session(.menu)
        visit.open(.startPlan)
        visit.showTopics()
        XCTAssertEqual(visit.route, .index)
        XCTAssertEqual(visit.progress.status(of: .startPlan), .inProgress(step: 1, of: 2))
    }

    func testFinishOnlyWorksFromTheLastStep() {
        var visit = session(.menu)
        visit.open(.startPlan)
        visit.finish()
        XCTAssertEqual(visit.route, .lesson(.startPlan, step: 1))
        XCTAssertFalse(visit.progress.isRead(.startPlan))
    }

    func testNextStopsAtTheLastStep() {
        var visit = session(.menu)
        visit.open(.followEnvelope)
        visit.next(); visit.next()
        XCTAssertEqual(visit.route, .lesson(.followEnvelope, step: 2))
    }

    func testFinishTopicMarksOnlyThatTopicReadAndReturnsToIndex() {
        var visit = session(.menu)
        visit.open(.paydayTransfers)
        visit.next(); visit.finish()
        XCTAssertEqual(visit.route, .index)
        XCTAssertTrue(visit.progress.isRead(.paydayTransfers))
        XCTAssertFalse(visit.progress.isRead(.introduction))
        XCTAssertEqual(PlanGuideMaterial.allCases.filter { visit.progress.isRead($0) }, [.paydayTransfers])
    }

    func testRereadStartsAtStepOneAndKeepsReadWhenClosedEarly() {
        var visit = session(.menu, finished(.allocationTypes))
        visit.open(.allocationTypes)
        XCTAssertEqual(visit.route, .lesson(.allocationTypes, step: 1))
        visit.next()
        XCTAssertEqual(visit.progress.status(of: .allocationTypes), .read)
        visit.showTopics()
        visit.open(.allocationTypes)
        XCTAssertEqual(visit.route, .lesson(.allocationTypes, step: 1))
    }

    func testRereadIntroKeepsTheInvitationHidden() {
        var visit = session(.menu, finished(.introduction))
        visit.open(.introduction)
        XCTAssertNil(PlanGuideInvitation.shown(hasPlan: false, progress: visit.progress))
    }

    func testEachMaterialKeepsItsOwnProgress() {
        var progress = reading(.introduction, to: 2)
        progress = finished(.startPlan, from: progress)
        progress = finished(.allocationTypes, from: progress)
        progress = reading(.managePlanItems, to: 2, from: progress)
        XCTAssertEqual(progress.status(of: .introduction), .inProgress(step: 2, of: 3))
        XCTAssertEqual(progress.status(of: .startPlan), .read)
        XCTAssertEqual(progress.status(of: .allocationTypes), .read)
        XCTAssertEqual(progress.status(of: .managePlanItems), .inProgress(step: 2, of: 2))
        XCTAssertEqual(progress.status(of: .paydayTransfers), .notStarted)
    }

    // MARK: - §6 Lifetime

    @MainActor
    func testProgressSurvivesARelaunch() throws {
        let suite = "PlanGuideTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let progress = finished(.startPlan, from: reading(.introduction, to: 2))
        PlanGuideStore(defaults: defaults).save(progress)
        XCTAssertEqual(PlanGuideStore(defaults: defaults).progress, progress)
    }

    @MainActor
    func testFreshInstallStartsWithNoProgress() throws {
        let suite = "PlanGuideTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(PlanGuideStore(defaults: defaults).progress, PlanGuideProgress())
    }

    @MainActor
    func testUnreadableSavedProgressStartsAfresh() throws {
        let suite = "PlanGuideTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("junk".utf8), forKey: PlanGuideStore.preferenceKey)
        XCTAssertEqual(PlanGuideStore(defaults: defaults).progress, PlanGuideProgress())
    }

    // MARK: - §4.2, §4.4 and §5 Content

    @MainActor
    func testEveryMaterialHasOneLessonPerStep() {
        for material in PlanGuideMaterial.allCases {
            XCTAssertEqual(PlanGuideContent.lessons(of: material).count, material.stepCount, "\(material)")
        }
    }

    @MainActor
    func testIntroSampleTotalsMatchTheBaseline() {
        let rows = PlanGuideContent.lessons(of: .introduction)[0].example.rows.map(\.value)
        XCTAssertEqual(rows, [8_000_000, 5_000_000, 3_000_000].map { Decimal($0).formattedIDR() })
    }

    @MainActor
    func testTransferExampleNeedsMatchTheDestinations() {
        let rows = PlanGuideContent.lessons(of: .paydayTransfers)[0].example.rows.map(\.value)
        XCTAssertEqual(rows, [2_800_000, 2_200_000].map { Decimal($0).formattedIDR() })
    }

    @MainActor
    func testPartialTransferSelectsHarianAndLeavesLiburan() {
        let example = PlanGuideContent.lessons(of: .paydayTransfers)[1].example
        XCTAssertEqual(example.rows.map(\.selection), [.selected, .unselected])
        XCTAssertEqual(example.summary?.value, Decimal(1_800_000).formattedIDR())
    }

    func testGuideKeysAreTranslatedIntoIndonesian() {
        let english = Locale(identifier: "en")
        let indonesian = Locale(identifier: "id")
        for key: LocalizedStringResource in [.guideIntro1Heading, .guideTidy2Takeaway2Body, .guideMeetPlan, .planGuide] {
            XCTAssertNotEqual(AppLocalization.string(key, locale: english), AppLocalization.string(key, locale: indonesian))
        }
    }
}
