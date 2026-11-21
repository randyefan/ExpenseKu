//
//  TourStore.swift
//  ExpenseKu
//
//  Whether the tour is done, and how far this device got (welcome-tour.md §4.1, §6). The
//  outcome lives in iCloud's key-value store beside payday, so a second device that has
//  not synced its Expenses yet does not replay the tour; chapter progress stays local.
//

import Foundation
import Observation
import SwiftUI

nonisolated struct TourLaunch: Identifiable, Hashable, Sendable {
    let entry: TourEntry
    let isReplay: Bool

    var id: String { "\(entry.id)-\(isReplay)" }
}

@MainActor
@Observable
final class TourStore {
    private static let outcomeKey = "welcomeTourOutcome"
    private static let progressKey = "welcomeTourProgress"

    private(set) var outcome: TourOutcome?
    private(set) var progress: TourProgress
    var launch: TourLaunch?

    @ObservationIgnored private let cloud: NSUbiquitousKeyValueStore
    @ObservationIgnored private let local: UserDefaults

    init(cloud: NSUbiquitousKeyValueStore = .default, local: UserDefaults = .standard) {
        self.cloud = cloud
        self.local = local
        outcome = cloud.string(forKey: Self.outcomeKey).flatMap(TourOutcome.init(rawValue:))
        progress = local.data(forKey: Self.progressKey)
            .flatMap { try? JSONDecoder().decode(TourProgress.self, from: $0) } ?? TourProgress()
    }

    func refresh() {
        outcome = cloud.string(forKey: Self.outcomeKey).flatMap(TourOutcome.init(rawValue:))
    }

    func record(_ outcome: TourOutcome?) {
        self.outcome = outcome
        if let outcome {
            cloud.set(outcome.rawValue, forKey: Self.outcomeKey)
        } else {
            cloud.removeObject(forKey: Self.outcomeKey)
        }
    }

    func record(_ progress: TourProgress) {
        self.progress = progress
        if let data = try? JSONEncoder().encode(progress) {
            local.set(data, forKey: Self.progressKey)
        }
    }

    func openIfDue(hasExpenses: Bool, isEphemeral: Bool) {
        guard launch == nil,
              let entry = TourAutoOpen.entry(outcome: outcome, progress: progress,
                                             hasExpenses: hasExpenses, isEphemeral: isEphemeral)
        else { return }
        launch = TourLaunch(entry: entry, isReplay: false)
    }
}

extension EnvironmentValues {
    @Entry var tour: TourSession?
}
