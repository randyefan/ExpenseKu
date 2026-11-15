//
//  PlanGuideRoute.swift
//  ExpenseKu
//

import Foundation

nonisolated enum PlanGuideRoute: Hashable {
    case index
    case lesson(PlanGuideMaterial, step: Int)
}
