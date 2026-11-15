//
//  PlanGuideScene.swift
//  ExpenseKu
//

import Foundation

nonisolated enum PlanGuideScene: Hashable, Sendable {
    case beforePayday
    case onPayday
    case throughTheCycle
    case chooseCycle
    case reuse
    case itemKinds
    case setAside
    case rowAndStatus
    case datesAndAuto
    case destinations
    case partialTransfer
    case envelopeFill
    case elsewhere
    case changeView
    case noticesAndClearing
}
