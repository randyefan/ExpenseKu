//
//  EnvelopeGatherSection.swift
//  ExpenseKu
//

import Foundation

/// One cycle's candidates in Move expenses here…: the envelope's own cycle, or an earlier
/// one whose expenses would be paid early (envelope-assignment.md §4.10.8).
nonisolated struct EnvelopeGatherSection: Identifiable {
    let cycle: PayCycle
    let isPaidEarly: Bool
    let expenses: [Expense]

    var id: Date { cycle.start }
}
