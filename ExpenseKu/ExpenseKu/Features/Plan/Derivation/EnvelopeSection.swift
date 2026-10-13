//
//  EnvelopeSection.swift
//  ExpenseKu
//

import Foundation

/// One cycle's envelopes in the picker: the expense's own under ENVELOPES, or a later
/// cycle's under "‹title› · Paid early" (envelope-assignment.md §4.10.2).
nonisolated struct EnvelopeSection: Identifiable {
    let cycle: PayCycle
    let isPaidEarly: Bool
    let envelopes: [PlanItem]
    let label: PaidEarlyLabel?

    var id: Date { cycle.start }
}
