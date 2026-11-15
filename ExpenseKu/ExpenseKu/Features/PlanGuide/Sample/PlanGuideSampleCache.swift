//
//  PlanGuideSampleCache.swift
//  ExpenseKu
//

import Foundation

@MainActor
final class PlanGuideSampleCache {
    private var samples: [PlanGuideSampleState: PlanGuideSample] = [:]

    func sample(_ state: PlanGuideSampleState) -> PlanGuideSample {
        if let sample = samples[state] { return sample }
        let sample = PlanGuideSample(state)
        samples[state] = sample
        return sample
    }
}
