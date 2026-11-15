//
//  PlanGuideMaterial.swift
//  ExpenseKu
//
//  The seven things the Plan guide can teach: the introduction and six topics
//  (plan-guide.md §4.2–§4.4). The raw values are what saved progress is keyed by, so
//  they must never be renamed.
//

import Foundation

nonisolated enum PlanGuideMaterial: String, CaseIterable, Codable, Hashable {
    case introduction
    case startPlan
    case allocationTypes
    case managePlanItems
    case paydayTransfers
    case followEnvelope
    case readAndTidy

    static let buildTopics: [PlanGuideMaterial] = [.startPlan, .allocationTypes, .managePlanItems]
    static let useTopics: [PlanGuideMaterial] = [.paydayTransfers, .followEnvelope, .readAndTidy]

    var stepCount: Int { spotlightCounts.count }

    var spotlightCounts: [Int] {
        switch self {
        case .introduction: [3, 3, 3]
        case .startPlan: [3, 3]
        case .allocationTypes: [3, 3]
        case .managePlanItems: [3, 3]
        case .paydayTransfers: [3, 4]
        case .followEnvelope: [5, 3]
        case .readAndTidy: [3, 2]
        }
    }

    func spotlightCount(ofStep step: Int) -> Int {
        spotlightCounts.indices.contains(step - 1) ? spotlightCounts[step - 1] : 1
    }
}
