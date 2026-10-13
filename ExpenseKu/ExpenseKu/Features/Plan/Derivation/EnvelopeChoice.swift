//
//  EnvelopeChoice.swift
//  ExpenseKu
//
//  What the owner chose for one expense in the editor's Envelope row or the bulk move
//  (docs/prd/envelope-assignment.md §4.3–4.6), held as an id so it can sit in a draft
//  and be compared for the discard guard.
//
//  On the expense it is two fields, because a nil assignment alone cannot tell
//  "By category" from "No envelope". Every write goes through `apply`, so the two
//  never disagree.
//

import Foundation
import SwiftData

nonisolated enum EnvelopeChoice: Hashable {
    case byCategory
    case noEnvelope
    case envelope(PersistentIdentifier)

    static func of(_ expense: Expense) -> EnvelopeChoice {
        if expense.isOutsideEnvelopes { return .noEnvelope }
        if let envelope = expense.envelope { return .envelope(envelope.persistentModelID) }
        return .byCategory
    }

    /// An assignment the envelopes on offer cannot hold falls back to By category —
    /// what moving the date into another cycle does (§4.4). No envelope names no plan,
    /// so it always survives.
    func kept(among envelopes: [PlanItem]) -> EnvelopeChoice {
        guard case .envelope(let id) = self else { return self }
        return envelopes.contains { $0.persistentModelID == id } ? self : .byCategory
    }

    func apply(to expense: Expense, envelopes: [PlanItem]) {
        switch self {
        case .byCategory:
            expense.envelope = nil
            expense.isOutsideEnvelopes = false
        case .noEnvelope:
            expense.envelope = nil
            expense.isOutsideEnvelopes = true
        case .envelope(let id):
            expense.envelope = envelopes.first { $0.persistentModelID == id }
            expense.isOutsideEnvelopes = false
        }
    }

    /// The bulk move. An expense a Fixed item created is already From plan and is
    /// never selectable, but the rule holds here too rather than trusting the caller.
    func apply(to expenses: [Expense], envelopes: [PlanItem]) {
        for expense in expenses where expense.planItem == nil {
            apply(to: expense, envelopes: envelopes)
        }
    }
}
