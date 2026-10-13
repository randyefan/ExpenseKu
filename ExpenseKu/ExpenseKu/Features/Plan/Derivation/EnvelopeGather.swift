//
//  EnvelopeGather.swift
//  ExpenseKu
//
//  What "Move expenses here…" offers for one envelope (envelope-assignment.md §4.9,
//  §4.10.8): every expense of its cycle that does not already count in it, newest first,
//  then — to pay early — those of each cycle from today's up to the one before it.
//
//  "Not already counting here" is asked of `EnvelopeClaims`, not of the assignment
//  field: a Makan claimed by Hidup is a candidate for Travelling, and so is one assigned
//  to another envelope. A Fixed item's expense is never offered — it is From plan
//  already and cannot be moved. An ended cycle is never offered: the reach is forward
//  from today, not back through history.
//

import Foundation
import SwiftData

nonisolated enum EnvelopeGather {
    static func candidates(for envelope: PlanItem, cycleExpenses: [Expense],
                           claims: EnvelopeClaims) -> [Expense] {
        cycleExpenses
            .filter { ExpenseSelection.isSelectable($0) }
            .filter { claims.envelope(for: $0)?.persistentModelID != envelope.persistentModelID }
            .sorted { $0.date > $1.date }
    }

    /// The envelope's own cycle first, unheaded; then each earlier cycle from the newest
    /// back to today's. A cycle with nothing to offer is left out.
    static func sections(for envelope: PlanItem, claims: EnvelopeClaims, expenses: [Expense],
                         payday: Int, calendar: Calendar, now: Date) -> [EnvelopeCycleSection] {
        let own = EnvelopeCycleSection(
            cycle: claims.cycle, isPaidEarly: false,
            expenses: candidates(for: envelope,
                                 cycleExpenses: expenses.filter { claims.cycle.contains($0.date) },
                                 claims: claims)
        )
        var sections = [own]
        let today = PayCycle.containing(now, payday: payday, calendar: calendar)
        var cycle = claims.cycle.previous(payday: payday, calendar: calendar)
        while cycle.start >= today.start {
            let earlier = expenses
                .filter { cycle.contains($0.date) && ExpenseSelection.isSelectable($0) }
                .filter { $0.envelope?.persistentModelID != envelope.persistentModelID }
                .sorted { $0.date > $1.date }
            sections.append(EnvelopeCycleSection(cycle: cycle, isPaidEarly: true, expenses: earlier))
            cycle = cycle.previous(payday: payday, calendar: calendar)
        }
        return sections.filter { !$0.expenses.isEmpty }
    }

    /// Where the sheet's query has to start to see every section.
    static func earliestStart(for envelopeCycle: PayCycle, payday: Int, calendar: Calendar, now: Date) -> Date {
        min(envelopeCycle.start, PayCycle.containing(now, payday: payday, calendar: calendar).start)
    }
}
