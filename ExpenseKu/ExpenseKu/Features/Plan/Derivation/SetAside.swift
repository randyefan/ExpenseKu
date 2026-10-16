//
//  SetAside.swift
//  ExpenseKu
//
//  Where a set-aside item sends its money (docs/prd/set-aside.md, ADR-0010): an envelope
//  of a *later* cycle's plan. October's "→ Jepang · Dec" is in October's Total cost, and
//  December's plan is credited with it.
//
//  The stored target is only half the fact. A target that was turned into a Fixed item,
//  or that a payday change re-cut into the same cycle or an earlier one, is ignored
//  (§4.9): the item still debits its own plan and credits nobody. Every reader goes
//  through `target(of:)` so a stale link can never credit a plan.
//

import Foundation
import SwiftData

nonisolated enum SetAside {
    static func target(of item: PlanItem) -> PlanItem? {
        guard item.isSetAside,
              let target = item.setAsideTarget, target.isEnvelope,
              let from = item.plan?.cycleStart,
              let to = target.plan?.cycleStart, to > from else { return nil }
        return target
    }

    /// The set-aside items crediting `envelope`, oldest cycle first.
    static func sources(into envelope: PlanItem) -> [PlanItem] {
        (envelope.setAsideSources ?? [])
            .filter { target(of: $0)?.persistentModelID == envelope.persistentModelID }
            .sorted { a, b in
                let aStart = a.plan?.cycleStart ?? .distantPast
                let bStart = b.plan?.cycleStart ?? .distantPast
                if aStart != bStart { return aStart < bStart }
                return a.createdAt < b.createdAt
            }
    }

    /// "Dec" for the row's title and the editor's For row, "December" for VoiceOver;
    /// nil when the item has no valid target.
    static func label(of item: PlanItem, payday: Int, calendar: Calendar) -> PaidEarlyLabel? {
        guard let target = target(of: item),
              let targetStart = target.plan?.cycleStart,
              let ownStart = item.plan?.cycleStart else { return nil }
        return PaidEarlyLabel(target: PayCycle.containing(targetStart, payday: payday, calendar: calendar),
                              from: PayCycle.containing(ownStart, payday: payday, calendar: calendar),
                              calendar: calendar)
    }

    /// The editor's For picker (§4.2, D1): paid early's later sections — every later cycle
    /// with a plan that has not ended, its active envelopes by planned amount ↓ — without
    /// the own cycle. The current target keeps its section, as the expense picker does.
    static func offer(for plan: CyclePlan, plans: [CyclePlan], keeping target: PlanItem?,
                      payday: Int, calendar: Calendar, now: Date) -> [EnvelopeSection] {
        let cycle = PayCycle.containing(plan.cycleStart, payday: payday, calendar: calendar)
        let keeping: EnvelopeChoice = target.map { .envelope($0.persistentModelID) } ?? .byCategory
        return EnvelopeOffer(cycle: cycle, plans: plans, payday: payday, calendar: calendar,
                             now: now, keeping: keeping)
            .sections.filter(\.isPaidEarly)
    }

    /// The month names of the cycles holding `items`, oldest first, for the delete
    /// confirmation (§4.9).
    static func months(of items: [PlanItem], payday: Int, calendar: Calendar) -> [String] {
        let cycles = Set(items.compactMap(\.plan?.cycleStart)
            .map { PayCycle.containing($0, payday: payday, calendar: calendar) })
        return cycles.sorted { $0.start < $1.start }
            .map { $0.lastDay(calendar: calendar).formatted(.dateTime.month(.wide)) }
    }
}
