//
//  PlanGuideSpotlight.swift
//  ExpenseKu
//
//  One stop of a lesson step (plan-guide-visual.md §4.3): what is lit, what the caption
//  says, and the sample state the example shows while it is lit.
//

import Foundation

nonisolated struct PlanGuideSpotlight: Hashable, Sendable {
    let target: PlanGuideTarget
    let caption: String
    let state: PlanGuideSampleState
    let swapsSnapshot: Bool

    typealias Change = @Sendable (inout PlanGuideSampleState) -> Void
}

extension [PlanGuideSpotlight] {
    static func walk(from start: PlanGuideSampleState = .baseline,
                     _ stops: [(PlanGuideTarget, String, PlanGuideSpotlight.Change?)]) -> [PlanGuideSpotlight] {
        var state = start
        return stops.map { target, caption, change in
            change?(&state)
            return PlanGuideSpotlight(target: target, caption: caption, state: state, swapsSnapshot: change != nil)
        }
    }
}
