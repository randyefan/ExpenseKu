//
//  PlanGuideSession.swift
//  ExpenseKu
//
//  One visit to the Plan guide: where it is, and the progress that visit has written
//  (plan-guide.md §4.5 and §6). Every move records the step it lands on, Back included,
//  so a Close at any point leaves the material resuming exactly there. Only Explore
//  topics and Finish topic mark anything Read, and each marks its own material alone.
//
//  Next and Back walk a step's spotlights before its steps (plan-guide-visual.md §4.4).
//  The spotlight is never saved (§5): progress keeps the format of the shipped guide.
//

import Foundation

nonisolated struct PlanGuideSession: Equatable {
    private(set) var route: PlanGuideRoute
    private(set) var progress: PlanGuideProgress
    private(set) var spotlight = 1

    init(entry: PlanGuideEntry, progress: PlanGuideProgress) {
        self.progress = progress
        route = .index
        if entry == .invitation { open(.introduction) }
    }

    var spotlightCount: Int {
        guard case .lesson(let material, let step) = route else { return 0 }
        return material.spotlightCount(ofStep: step)
    }

    var isAtStart: Bool {
        guard case .lesson(_, let step) = route else { return false }
        return step == 1 && spotlight == 1
    }

    var isAtEnd: Bool {
        guard case .lesson(let material, let step) = route else { return false }
        return step == material.stepCount && spotlight == spotlightCount
    }

    mutating func open(_ material: PlanGuideMaterial) {
        show(progress.openingStep(of: material), of: material, spotlight: 1)
    }

    mutating func next() {
        guard case .lesson(let material, let step) = route else { return }
        if spotlight < spotlightCount {
            spotlight += 1
        } else if step < material.stepCount {
            show(step + 1, of: material, spotlight: 1)
        }
    }

    mutating func back() {
        guard case .lesson(let material, let step) = route else { return }
        if spotlight > 1 {
            spotlight -= 1
        } else if step > 1 {
            show(step - 1, of: material, spotlight: material.spotlightCount(ofStep: step - 1))
        }
    }

    mutating func showTopics() {
        route = .index
        spotlight = 1
    }

    mutating func finish() {
        guard case .lesson(let material, _) = route, isAtEnd else { return }
        progress.finish(material)
        route = .index
        spotlight = 1
    }

    private mutating func show(_ step: Int, of material: PlanGuideMaterial, spotlight: Int) {
        progress.display(step: step, of: material)
        route = .lesson(material, step: step)
        self.spotlight = spotlight
    }
}
