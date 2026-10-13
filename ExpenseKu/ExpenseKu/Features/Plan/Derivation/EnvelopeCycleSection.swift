//
//  EnvelopeCycleSection.swift
//  ExpenseKu
//

import Foundation

/// One cycle's expenses in a list about one envelope: its own cycle, or an earlier one
/// whose expenses are — or would be — paid early into it. Move expenses here… lists
/// candidates this way (envelope-assignment.md §4.10.8), the envelope's detail what it
/// already counts (envelope-detail.md §4.4).
nonisolated struct EnvelopeCycleSection: Identifiable {
    let cycle: PayCycle
    let isPaidEarly: Bool
    let expenses: [Expense]

    var id: Date { cycle.start }
}
