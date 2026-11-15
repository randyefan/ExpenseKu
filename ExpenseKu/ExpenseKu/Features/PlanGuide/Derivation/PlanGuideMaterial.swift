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

    var stepCount: Int { self == .introduction ? 3 : 2 }
}
