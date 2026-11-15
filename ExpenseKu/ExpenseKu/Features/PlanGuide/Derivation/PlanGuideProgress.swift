//
//  PlanGuideProgress.swift
//  ExpenseKu
//
//  What the owner has read of the Plan guide (plan-guide.md §4.3, §4.5 and §6). Each
//  material keeps its own last displayed step and Read flag, so finishing one never
//  touches another, and Read survives a reread that is closed early.
//
//  Local to the device on purpose: guide progress is not data, and a fresh install or
//  another device starts the guide afresh (§3, §6).
//

import Foundation

nonisolated struct PlanGuideProgress: Codable, Equatable {
    private var materials: [PlanGuideMaterial: PlanGuideMaterialProgress] = [:]

    func status(of material: PlanGuideMaterial) -> PlanGuideStatus {
        guard let progress = materials[material] else { return .notStarted }
        if progress.isRead { return .read }
        return .inProgress(step: progress.lastStep, of: material.stepCount)
    }

    func isRead(_ material: PlanGuideMaterial) -> Bool {
        materials[material]?.isRead ?? false
    }

    /// A Read material starts over; anything else resumes where it was left.
    func openingStep(of material: PlanGuideMaterial) -> Int {
        guard let progress = materials[material], !progress.isRead else { return 1 }
        return min(max(progress.lastStep, 1), material.stepCount)
    }

    mutating func display(step: Int, of material: PlanGuideMaterial) {
        let isRead = isRead(material)
        materials[material] = PlanGuideMaterialProgress(lastStep: step, isRead: isRead)
    }

    mutating func finish(_ material: PlanGuideMaterial) {
        materials[material] = PlanGuideMaterialProgress(lastStep: 1, isRead: true)
    }
}
