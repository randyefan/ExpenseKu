//
//  PlanGuideTarget.swift
//  ExpenseKu
//

import Foundation

nonisolated enum PlanGuideTarget: Hashable, Sendable {
    case incomeLine
    case planRows
    case remainingLine
    case transferChecklist
    case movedButton
    case kosRow
    case harianRow
    case cycleHeader
    case addPlanItem
    case copyFrom
    case startEmpty
    case lookBackRow
    case liburanRow
    case rowBody
    case check
    case dueChip
    case autoChip
    case liburanPick
    case transferNow
    case envelopeBar
    case envelopeAdd
    case editorEnvelope
    case paidElsewhereRow
    case paidEarlyRow
    case sortMenu
    case accountGroups
    case groupShares
    case reviewNotice
    case clearPlan
    case openMenu
}
