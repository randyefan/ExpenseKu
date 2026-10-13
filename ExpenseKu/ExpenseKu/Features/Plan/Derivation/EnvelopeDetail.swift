//
//  EnvelopeDetail.swift
//  ExpenseKu
//
//  What an envelope's detail lists (docs/prd/envelope-detail.md §4.4): every expense the
//  envelope counts, so the list can be checked against the bar to the rupiah.
//
//  It decides nothing about where an expense counts. Its own cycle's expenses are the
//  ones `EnvelopeClaims.envelope(for:)` puts here, and the earlier ones are what
//  `paidEarly(into:)` returns — the same two calls `EnvelopeSpend` sums, so the list and
//  `EnvelopeProgress.spent` cannot drift apart. A second resolver here would be the
//  first place a rupiah could be shown in one envelope and counted in another.
//
//  The envelope's own cycle comes first and unheaded, then one section per earlier cycle
//  that paid into it, newest first — the shape Move expenses here… already uses.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeDetail {
    let sections: [EnvelopeCycleSection]

    init(envelope: PlanItem, claims: EnvelopeClaims, cycleExpenses: [Expense],
         payday: Int, calendar: Calendar) {
        let id = envelope.persistentModelID
        let own = cycleExpenses
            .filter { claims.cycle.contains($0.date) && claims.envelope(for: $0)?.persistentModelID == id }
            .sorted { $0.date > $1.date }
        let early = Dictionary(grouping: claims.paidEarly(into: envelope)) {
            PayCycle.containing($0.date, payday: payday, calendar: calendar)
        }
        let earlier = early.keys.sorted { $0.start > $1.start }.map { cycle in
            EnvelopeCycleSection(cycle: cycle, isPaidEarly: true,
                                 expenses: (early[cycle] ?? []).sorted { $0.date > $1.date })
        }
        sections = ([EnvelopeCycleSection(cycle: claims.cycle, isPaidEarly: false, expenses: own)] + earlier)
            .filter { !$0.expenses.isEmpty }
    }

    var expenses: [Expense] { sections.flatMap(\.expenses) }

    var isEmpty: Bool { sections.isEmpty }

    var total: Decimal { expenses.reduce(Decimal(0)) { $0 + $1.amount } }

    /// "Bensin · E-money · Makan", or "Assigned expenses only" — the row's own wording
    /// for what the envelope claims (envelope-assignment.md §4.2).
    static func claimsLine(for envelope: PlanItem) -> String {
        let names = claimedNames(of: envelope)
        return names.isEmpty ? "Assigned expenses only" : names.joined(separator: " · ")
    }

    static func emptyTitle(for envelope: PlanItem) -> String {
        "Nothing in \(displayName(of: envelope)) yet"
    }

    /// §4.5. The list is joined by hand rather than with `.list(type: .and)`, whose
    /// Oxford comma depends on the device's region.
    static func emptyMessage(for envelope: PlanItem) -> String {
        let names = claimedNames(of: envelope)
        guard let last = names.last else {
            return "Only expenses you assign land here. Use ＋ to add one or move some in."
        }
        let list = names.count == 1 ? last : names.dropLast().joined(separator: ", ") + " and " + last
        return "\(list) expenses this cycle land here by themselves."
    }

    static func displayName(of envelope: PlanItem) -> String {
        envelope.name.isEmpty ? "Untitled" : envelope.name
    }

    /// §4.6: the detail comes back after another sheet only while its envelope is still
    /// one the Plan lens draws as an active Envelope row. A deleted envelope has nothing
    /// to show, and a dormant one is folded away where a detail is not offered.
    static func canReopen(_ envelope: PlanItem) -> Bool {
        guard !envelope.isDeleted, envelope.modelContext != nil, envelope.plan != nil else { return false }
        return envelope.isEnvelope && !PlanDormancy.isDormant(envelope)
    }

    private static func claimedNames(of envelope: PlanItem) -> [String] {
        (envelope.envelopeCategories ?? []).map(\.name).sorted()
    }
}
