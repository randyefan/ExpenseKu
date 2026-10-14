//
//  PaidEarlyShift.swift
//  ExpenseKu
//
//  Money paid early moves between two plans (envelope-assignment.md §4.10.10, flow U).
//  The ticket bought on 14 Oct for November's Travelling left October's money, so
//  October's Sisa falls by it in full and November's rises by it — capped at what
//  Travelling planned, so November never gains more than it set aside.
//
//  Total cost stays Σ planned: each side shows the shift as its own reconciling row,
//  and the transfer lines and Group shares read an envelope net of its credit. Derived
//  per read from the assignments through `EnvelopeClaims`, never stored, so deleting
//  the envelope or reassigning the expense moves both sides at once.
//

import Foundation
import SwiftData

nonisolated struct PaidEarlyShift: Equatable {
    /// Σ of this cycle's expenses paid early into later cycles, in full.
    let outgoing: Decimal
    /// The start of each later cycle the outgoing money went to.
    let outgoingCycleStarts: [Date]
    /// Σ over this cycle's envelopes of min(paid early into it, its planned amount).
    let incoming: Decimal
    /// The dates of the paid-early expenses behind `incoming`.
    let incomingDates: [Date]
    let credits: [PersistentIdentifier: Decimal]

    static let none = PaidEarlyShift(outgoing: 0, outgoingCycleStarts: [], incoming: 0,
                                     incomingDates: [], credits: [:])

    init(outgoing: Decimal, outgoingCycleStarts: [Date], incoming: Decimal,
         incomingDates: [Date], credits: [PersistentIdentifier: Decimal]) {
        self.outgoing = outgoing
        self.outgoingCycleStarts = outgoingCycleStarts
        self.incoming = incoming
        self.incomingDates = incomingDates
        self.credits = credits
    }

    init(cycleExpenses: [Expense], claims: EnvelopeClaims, envelopes: [EnvelopeProgress]) {
        var outgoing: Decimal = 0
        var starts: [Date] = []
        for expense in cycleExpenses {
            guard let target = claims.paidEarlyTarget(of: expense) else { continue }
            outgoing += expense.amount
            if let start = target.plan?.cycleStart { starts.append(start) }
        }

        var credits: [PersistentIdentifier: Decimal] = [:]
        var dates: [Date] = []
        for envelope in envelopes {
            let credit = min(envelope.paidEarly, max(envelope.planned, 0))
            guard credit > 0 else { continue }
            credits[envelope.itemID] = credit
            dates += envelope.paidEarlyDates
        }

        self.init(outgoing: outgoing, outgoingCycleStarts: starts,
                  incoming: credits.values.reduce(0, +), incomingDates: dates, credits: credits)
    }

    func credit(for item: PlanItem) -> Decimal {
        credits[item.persistentModelID] ?? 0
    }

    /// "Paid early for November", or "Paid early for later cycles"; nil at Rp 0.
    func outgoingLabel(payday: Int, calendar: Calendar) -> String? {
        guard outgoing > 0 else { return nil }
        guard let month = Self.month(of: outgoingCycleStarts, payday: payday, calendar: calendar) else {
            return "Paid early for later cycles"
        }
        return "Paid early for \(month)"
    }

    /// "Paid early in October", or "Paid early"; nil at Rp 0.
    func incomingLabel(payday: Int, calendar: Calendar) -> String? {
        guard incoming > 0 else { return nil }
        guard let month = Self.month(of: incomingDates, payday: payday, calendar: calendar) else {
            return "Paid early"
        }
        return "Paid early in \(month)"
    }

    private static func month(of dates: [Date], payday: Int, calendar: Calendar) -> String? {
        let cycles = Set(dates.map { PayCycle.containing($0, payday: payday, calendar: calendar) })
        guard cycles.count == 1, let cycle = cycles.first else { return nil }
        return cycle.lastDay(calendar: calendar).formatted(.dateTime.month(.wide))
    }
}
