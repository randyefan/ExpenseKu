//
//  SetAsideShift.swift
//  ExpenseKu
//
//  Money set aside in earlier plans arriving in this one (docs/prd/set-aside.md §4.5).
//  The earlier side needs nothing here: a set-aside line is an ordinary item of its own
//  plan, already in its Total cost. This side gains one reconciling row under Total
//  cost, "Set aside in October", and Sisa rises by it.
//
//  Not capped — *owner override*: setting aside Rp 25.000.000 for a Rp 20.000.000 Jepang
//  credits the whole Rp 25.000.000, and the extra is free money here. Paid early keeps
//  its own cap (`PaidEarlyShift`), untouched by this.
//

import Foundation
import SwiftData

nonisolated struct SetAsideShift: Equatable {
    /// Σ over this cycle's envelopes of what earlier plans set aside for them.
    let incoming: Decimal
    /// The start of each earlier plan's cycle the money came from.
    let sourceCycleStarts: [Date]
    let credits: [PersistentIdentifier: Decimal]

    static let none = SetAsideShift(incoming: 0, sourceCycleStarts: [], credits: [:])

    init(incoming: Decimal, sourceCycleStarts: [Date], credits: [PersistentIdentifier: Decimal]) {
        self.incoming = incoming
        self.sourceCycleStarts = sourceCycleStarts
        self.credits = credits
    }

    init(envelopes: [EnvelopeProgress]) {
        var credits: [PersistentIdentifier: Decimal] = [:]
        var starts: [Date] = []
        for envelope in envelopes where envelope.setAside > 0 {
            credits[envelope.itemID] = envelope.setAside
            starts += envelope.setAsideCycleStarts
        }
        self.init(incoming: credits.values.reduce(0, +), sourceCycleStarts: starts, credits: credits)
    }

    func credit(for item: PlanItem) -> Decimal {
        credits[item.persistentModelID] ?? 0
    }

    /// "Set aside in October", or "Set aside earlier"; nil at Rp 0.
    func incomingLabel(payday: Int, calendar: Calendar) -> String? {
        guard incoming > 0 else { return nil }
        let cycles = Set(sourceCycleStarts.map { PayCycle.containing($0, payday: payday, calendar: calendar) })
        guard cycles.count == 1, let cycle = cycles.first else { return "Set aside earlier" }
        return "Set aside in \(cycle.lastDay(calendar: calendar).formatted(.dateTime.month(.wide)))"
    }
}
