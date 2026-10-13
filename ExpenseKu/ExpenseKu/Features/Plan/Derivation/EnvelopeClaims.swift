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
//  An assignment counts here while its envelope is one of *these*: the envelopes of the
//  plan of the expense's own cycle. One pointing at a *later* cycle's plan is paid early
//  (envelope-assignment.md §4.10, ADR-0009): it counts in that envelope, in that cycle,
//  and here in none — never falling back to its Category, or the ticket would be in
//  October's Hidup and November's Travelling at once. One pointing at an earlier cycle is
//  ignored: the editor never offers it, but a payday change re-cuts every cycle without
//  touching a single expense, and this is the guard for that.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeClaims {
    let cycle: PayCycle
    private let envelopes: [PersistentIdentifier: PlanItem]
    private let byCategory: [PersistentIdentifier: PlanItem]

    init(envelopes: [PlanItem], cycle: PayCycle) {
        self.cycle = cycle
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
        if let assigned = expense.envelope {
            if let envelope = envelopes[assigned.persistentModelID] { return envelope }
            if isLater(assigned) { return nil }
        }
        return claimant(of: expense.category)
    }

    /// The later cycle's envelope an expense of this cycle was paid early into.
    func paidEarlyTarget(of expense: Expense) -> PlanItem? {
        guard expense.planItem == nil, !expense.isOutsideEnvelopes,
              let assigned = expense.envelope, envelopes[assigned.persistentModelID] == nil,
              isLater(assigned) else { return nil }
        return assigned
    }

    /// The expenses dated before this cycle that one of its envelopes counts: paid early.
    func paidEarly(into envelope: PlanItem) -> [Expense] {
        guard contains(envelope) else { return [] }
        return (envelope.assignedExpenses ?? []).filter {
            $0.date < cycle.start && $0.planItem == nil && !$0.isOutsideEnvelopes
        }
    }

    func claimant(of category: Category?) -> PlanItem? {
        category.flatMap { byCategory[$0.persistentModelID] }
    }

    func contains(_ envelope: PlanItem) -> Bool {
        envelopes[envelope.persistentModelID] != nil
    }

    private func isLater(_ envelope: PlanItem) -> Bool {
        guard let start = envelope.plan?.cycleStart else { return false }
        return start >= cycle.end
    }
}
