//
//  PlanGuideStatus.swift
//  ExpenseKu
//

import Foundation

nonisolated enum PlanGuideStatus: Equatable {
    case notStarted
    case inProgress(step: Int, of: Int)
    case read
}
