//
//  PlanGuideInvitation.swift
//  ExpenseKu
//
//  The Meet Plan card in a cycle with no plan (plan-guide.md §4.1). It belongs to the
//  introduction alone: finishing the introduction hides it even with every topic unread,
//  and any plan at all, even an empty one, hides it too.
//

import Foundation

nonisolated enum PlanGuideInvitation: Equatable {
    case view
    case resume

    static func shown(hasPlan: Bool, progress: PlanGuideProgress) -> PlanGuideInvitation? {
        guard !hasPlan else { return nil }
        switch progress.status(of: .introduction) {
        case .read: return nil
        case .notStarted: return .view
        case .inProgress: return .resume
        }
    }
}
