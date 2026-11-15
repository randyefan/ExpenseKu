//
//  PlanGuideSampleState.swift
//  ExpenseKu
//
//  One state of the guide's November sample (plan-guide-visual.md §4.5): the baseline of
//  plan-guide.md §5 plus whatever a spotlight's snapshot changed. Equal states draw the
//  same example, so the guide builds each one once.
//

import Foundation

nonisolated struct PlanGuideSampleState: Hashable, Sendable {
    enum KosStatus: Hashable, Sendable {
        case planned
        case funded
        case done
        case autoPosted
    }

    var gajiArrived = false
    var kos = KosStatus.planned
    var kosHasAccount = true
    var kosIsAuto = false
    var harianSpent: Decimal = 0
    var harianFunded = false
    var liburanChosen = true
    var paidElsewhereMoved = false
    var paidEarlyTicket = false
    var sort = PlanSort.amount

    static let baseline = PlanGuideSampleState()

    static let harianEveryday: Decimal = 120_000
    static let harianWithMakan: Decimal = 165_000
    static let harianOverspent: Decimal = 1_950_000
}
