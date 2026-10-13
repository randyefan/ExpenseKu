//
//  EnvelopeClaims.swift
//  ExpenseKu
//
//  Which envelope, if any, one expense counts in (docs/prd/envelope-assignment.md §4.1).
//  The envelope bar, the List header split, the plan filter, the row tags and the
//  Insights drill-in all resolve through here, so they can never disagree about where
//  a rupiah went.
//
//  The order is the rule. An expense a Fixed item created counts in no envelope
//  (payday-planning.md §5.2). One the owner marked No envelope counts in none either.
//  One the owner assigned counts in that envelope alone — even though another envelope
//  claims its Category, which is the whole point: a meal on a trip is still Makan, and
//  must not also eat into Hidup. Everything else falls to the Category claim.
//
//  An assignment only counts while its envelope is one of *these*: the envelopes of the
//  plan of the expense's own cycle. The editor resets an assignment when the date
//  leaves the cycle, but a payday change re-cuts every cycle without touching a single
//  expense, and this is the guard for that.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeClaims {
    private let envelopes: [PersistentIdentifier: PlanItem]
    private let byCategory: [PersistentIdentifier: PlanItem]

    init(envelopes: [PlanItem]) {
        var all: [PersistentIdentifier: PlanItem] = [:]
        var claimed: [PersistentIdentifier: PlanItem] = [:]
        for envelope in envelopes where envelope.isEnvelope {
            all[envelope.persistentModelID] = envelope
            for category in envelope.envelopeCategories ?? [] {
                claimed[category.persistentModelID] = envelope
            }
        }
        self.envelopes = all
        byCategory = claimed
    }

    var isEmpty: Bool { envelopes.isEmpty }

    func envelope(for expense: Expense) -> PlanItem? {
        guard expense.planItem == nil, !expense.isOutsideEnvelopes else { return nil }
        if let assigned = expense.envelope, let envelope = envelopes[assigned.persistentModelID] {
            return envelope
        }
        return claimant(of: expense.category)
    }

    func claimant(of category: Category?) -> PlanItem? {
        category.flatMap { byCategory[$0.persistentModelID] }
    }

    func contains(_ envelope: PlanItem) -> Bool {
        envelopes[envelope.persistentModelID] != nil
    }
}
