//
//  TourProgress.swift
//  ExpenseKu
//
//  Chapter progress is local to the device; the outcome syncs through iCloud beside payday
//  (welcome-tour.md §4.1).
//

import Foundation

nonisolated enum TourOutcome: String, Codable, Sendable {
    case finished
    case skipped
}

nonisolated struct TourProgress: Codable, Equatable, Sendable {
    var started: TourChapter?
    var done: Set<TourChapter> = []

    var doneCount: Int { done.count }

    func starting(_ chapter: TourChapter) -> TourProgress {
        TourProgress(started: chapter, done: done)
    }

    func finishing(_ chapter: TourChapter) -> TourProgress {
        TourProgress(started: started, done: done.union([chapter]))
    }

    func leaving() -> TourProgress {
        TourProgress(started: nil, done: done)
    }
}

nonisolated enum TourEntry: Hashable, Identifiable, Sendable {
    case opening
    case chapter(TourChapter)

    var id: String {
        switch self {
        case .opening: "opening"
        case .chapter(let chapter): "chapter\(chapter.rawValue)"
        }
    }
}

nonisolated enum TourAutoOpen {
    static func entry(outcome: TourOutcome?, progress: TourProgress, hasExpenses: Bool,
                      isEphemeral: Bool) -> TourEntry? {
        guard outcome == nil, !hasExpenses, !isEphemeral else { return nil }
        return progress.started.map(TourEntry.chapter) ?? .opening
    }

    static func outcome(afterSkipping current: TourOutcome?, isReplay: Bool) -> TourOutcome? {
        isReplay ? current : .skipped
    }
}
