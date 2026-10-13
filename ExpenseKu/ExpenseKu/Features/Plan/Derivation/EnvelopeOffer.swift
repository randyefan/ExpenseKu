//
//  EnvelopeOffer.swift
//  ExpenseKu
//
//  Which envelopes an expense of one cycle may be put in (envelope-assignment.md §4.4,
//  §4.10.2): its own cycle's, then — paid early — those of every later cycle whose plan
//  already exists and has not ended. The editor's row and picker, the Move sheet and the
//  long-press item all read this, so they can never disagree about what is on offer.
//
//  Only plans that exist count. A later plan is made by paging the Plan lens forward,
//  never here: offering an envelope must not write one.
//
//  An ended cycle is not offered — paying a closed month ahead means nothing — unless the
//  expense is already in one of its envelopes. That section stays, so the picker can still
//  show the checkmark; counting never had a time limit, only offering does.
//

import Foundation
import SwiftData

nonisolated struct EnvelopeOffer {
    let cycle: PayCycle
    let sections: [EnvelopeSection]

    init(cycle: PayCycle, plans: [CyclePlan], payday: Int, calendar: Calendar, now: Date,
         keeping choice: EnvelopeChoice = .byCategory) {
        self.cycle = cycle
        var sections: [EnvelopeSection] = []
        let own = Self.activeEnvelopes(of: PlanLookup.plan(for: cycle, in: plans))
        if !own.isEmpty {
            sections.append(EnvelopeSection(cycle: cycle, isPaidEarly: false, envelopes: own, label: nil))
        }
        let later = Set(plans.filter { $0.cycleStart >= cycle.end }
            .map { PayCycle.containing($0.cycleStart, payday: payday, calendar: calendar) })
        for laterCycle in later.sorted(by: { $0.start < $1.start }) {
            let envelopes = Self.activeEnvelopes(of: PlanLookup.plan(for: laterCycle, in: plans))
            guard !envelopes.isEmpty,
                  laterCycle.end > now || envelopes.contains(where: { choice == .envelope($0.persistentModelID) })
            else { continue }
            sections.append(EnvelopeSection(
                cycle: laterCycle, isPaidEarly: true, envelopes: envelopes,
                label: PaidEarlyLabel(target: laterCycle, from: cycle, calendar: calendar)
            ))
        }
        self.sections = sections
    }

    var isEmpty: Bool { sections.isEmpty }

    var envelopes: [PlanItem] { sections.flatMap(\.envelopes) }

    func section(of envelopeID: PersistentIdentifier) -> EnvelopeSection? {
        sections.first { $0.envelopes.contains { $0.persistentModelID == envelopeID } }
    }

    /// A plan's active envelopes, by planned amount ↓, name — the Plan lens's default order.
    static func activeEnvelopes(of plan: CyclePlan?) -> [PlanItem] {
        PlanDormancy.split(plan?.items ?? []).active.filter(\.isEnvelope)
    }
}
