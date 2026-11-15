//
//  PlanGuideStore.swift
//  ExpenseKu
//
//  Guide progress in UserDefaults rather than SwiftData: it is a device preference, not
//  the owner's data, so it needs no schema version and must not sync (plan-guide.md §3).
//

import Foundation
import Observation

@Observable
final class PlanGuideStore {
    static let preferenceKey = "planGuideProgress"

    private(set) var progress: PlanGuideProgress
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        progress = defaults.data(forKey: Self.preferenceKey)
            .flatMap { try? JSONDecoder().decode(PlanGuideProgress.self, from: $0) } ?? PlanGuideProgress()
    }

    func save(_ progress: PlanGuideProgress) {
        guard progress != self.progress else { return }
        self.progress = progress
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: Self.preferenceKey)
        }
    }
}
