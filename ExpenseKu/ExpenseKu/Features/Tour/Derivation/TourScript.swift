//
//  TourScript.swift
//  ExpenseKu
//
//  The four chapters as beats (welcome-tour.md §4.5). Only October's line depends on the
//  sample, because the last cycle is named after today's.
//

import Foundation

nonisolated struct TourMission: Equatable, Sendable {
    let beats: [TourBeat]
}

nonisolated struct TourPosition: Equatable, Hashable, Sendable {
    let chapter: TourChapter
    var mission: Int
    var beat: Int

    static func start(of chapter: TourChapter) -> TourPosition {
        TourPosition(chapter: chapter, mission: 0, beat: 0)
    }
}

nonisolated struct TourScript: Sendable {
    let lastCycleName: String

    static let makan = "Makan"
    static let ibu = "Ibu"
    static let jago = "Jago"
    static let recordedAmount: Decimal = 45_000
    static let searchQuery = "kopi"

    func missions(in chapter: TourChapter) -> [TourMission] {
        switch chapter {
        case .record: record
        case .browse: browse
        case .plan: plan
        case .insights: insights
        }
    }

    func beat(at position: TourPosition) -> TourBeat? {
        let missions = missions(in: position.chapter)
        guard missions.indices.contains(position.mission) else { return nil }
        let beats = missions[position.mission].beats
        guard beats.indices.contains(position.beat) else { return nil }
        return beats[position.beat]
    }

    enum Step: Equatable, Sendable {
        case beat(TourPosition)
        case missionDone(next: TourPosition)
        case chapterDone
    }

    func step(after position: TourPosition) -> Step {
        let missions = missions(in: position.chapter)
        guard missions.indices.contains(position.mission) else { return .chapterDone }
        if position.beat + 1 < missions[position.mission].beats.count {
            return .beat(TourPosition(chapter: position.chapter, mission: position.mission, beat: position.beat + 1))
        }
        if position.mission + 1 < missions.count {
            return .missionDone(next: TourPosition(chapter: position.chapter, mission: position.mission + 1, beat: 0))
        }
        return .chapterDone
    }

    func fill(of chapter: TourChapter, at position: TourPosition?, done: Set<TourChapter>) -> Double {
        if done.contains(chapter) { return 1 }
        guard let position, position.chapter == chapter else { return 0 }
        let count = missions(in: chapter).count
        return count == 0 ? 0 : Double(position.mission) / Double(count)
    }

    private var record: [TourMission] {
        [
            TourMission(beats: [
                TourBeat(kind: .act(.editorOpened), line: .recordAdd, target: .addExpense, nudge: .recordAddNudge),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.amount(Self.recordedAmount)), line: .recordKeypad, target: .keypad,
                         readout: .amountReadout, nudge: .recordKeypadNudge),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.category(Self.makan)), line: .recordCategory, target: .categoryGrid,
                         nudge: .recordCategoryNudge, command: .scrollEditor(.categoryGrid)),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.person(Self.ibu)), line: .recordPerson, target: .peopleRail,
                         nudge: .recordPersonNudge, command: .scrollEditor(.peopleRail)),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.account(Self.jago)), line: .recordAccount, target: .accountRow,
                         nudge: .recordAccountNudge, command: .scrollEditor(.accountRow)),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.saved), line: .recordSave, target: .saveKey, nudge: .recordSaveNudge),
                TourBeat(kind: .moment, line: .recordSaved, target: .landedRow),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.receiptTapped), line: .recordReceipt, target: .readReceipt,
                         nudge: .recordReceiptNudge, command: .openEditor),
                TourBeat(kind: .watch(.receiptFilled), line: .recordReceiptReading),
                TourBeat(kind: .act(.saved), line: .recordReceiptCheck, target: .saveKey, nudge: .recordSaveNudge),
                TourBeat(kind: .moment, line: .recordReceiptSaved, target: .landedRow),
            ]),
        ]
    }

    private var browse: [TourMission] {
        [
            TourMission(beats: [
                TourBeat(kind: .act(.cycle(isCurrent: false)), line: .browsePrevious, target: .previousCycle,
                         nudge: .browsePreviousNudge),
                TourBeat(kind: .act(.cycle(isCurrent: true)), line: .browseLastCycle(lastCycleName),
                         target: .nextCycle, nudge: .browseNextNudge),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.lens(.month)), line: .browseMonth, target: .monthLens, nudge: .browseMonthNudge),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.searchOpened), line: .browseSearch, target: .searchButton,
                         nudge: .browseSearchNudge),
                TourBeat(kind: .act(.search(Self.searchQuery)), line: .browseSearchType, target: .searchField,
                         readout: .searchResults, nudge: .browseSearchTypeNudge),
            ]),
        ]
    }

    private var plan: [TourMission] {
        [
            TourMission(beats: [
                TourBeat(kind: .act(.lens(.plan)), line: .planLens, target: .planLens, nudge: .planLensNudge,
                         command: .clearSearch),
            ]),
            TourMission(beats: [
                TourBeat(kind: .spotlight, line: .planIncome, target: .incomeLine, nudge: .spotlightNudge),
                TourBeat(kind: .spotlight, line: .planHarian, target: .harianRow, nudge: .spotlightNudge,
                         command: .revealPlanRows),
                TourBeat(kind: .spotlight, line: .planRemaining, target: .remainingLine, companion: .planOptions,
                         nudge: .spotlightNudge),
            ]),
        ]
    }

    private var insights: [TourMission] {
        [
            TourMission(beats: [
                TourBeat(kind: .act(.tab(.insights)), line: .insightsTab, target: .insightsTab,
                         nudge: .insightsTabNudge),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.categoryDetail(Self.makan)), line: .insightsMakan, target: .makanBar,
                         nudge: .insightsMakanNudge),
                TourBeat(kind: .moment, line: .insightsMakanFound, target: .recordedRow, command: .showToday),
            ]),
            TourMission(beats: [
                TourBeat(kind: .act(.leaderboard), line: .insightsLeaderboard, target: .leaderboardCard,
                         nudge: .insightsLeaderboardNudge, command: .popInsights),
                TourBeat(kind: .moment, line: .insightsIbuFirst, target: .topRank),
            ]),
        ]
    }
}
