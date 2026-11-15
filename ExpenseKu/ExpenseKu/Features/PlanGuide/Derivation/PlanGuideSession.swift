//
//  PlanGuideSession.swift
//  ExpenseKu
//
//  One visit to the Plan guide: where it is, and the progress that visit has written
//  (plan-guide.md §4.5 and §6). Every move records the step it lands on, Back included,
//  so a Close at any point leaves the material resuming exactly there. Only Explore
//  topics and Finish topic mark anything Read, and each marks its own material alone.
//

import Foundation

nonisolated struct PlanGuideSession: Equatable {
    private(set) var route: PlanGuideRoute
    private(set) var progress: PlanGuideProgress

    init(entry: PlanGuideEntry, progress: PlanGuideProgress) {
        self.progress = progress
        route = .index
        if entry == .invitation { open(.introduction) }
    }

    mutating func open(_ material: PlanGuideMaterial) {
        show(progress.openingStep(of: material), of: material)
    }

    mutating func next() {
        guard case .lesson(let material, let step) = route, step < material.stepCount else { return }
        show(step + 1, of: material)
    }

    mutating func back() {
        guard case .lesson(let material, let step) = route, step > 1 else { return }
        show(step - 1, of: material)
    }

    mutating func showTopics() {
        route = .index
    }

    mutating func finish() {
        guard case .lesson(let material, let step) = route, step == material.stepCount else { return }
        progress.finish(material)
        route = .index
    }

    private mutating func show(_ step: Int, of material: PlanGuideMaterial) {
        progress.display(step: step, of: material)
        route = .lesson(material, step: step)
    }
}
