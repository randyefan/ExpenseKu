//
//  EnvelopeGather.swift
//  ExpenseKu
//
//  What "Move expenses here…" offers for one envelope (envelope-assignment.md §4.9):
//  every expense of its cycle that does not already count in it, newest first.
//
//  "Not already counting here" is asked of `EnvelopeClaims`, not of the assignment
//  field: a Makan claimed by Hidup is a candidate for Travelling, and so is one assigned
//  to another envelope. A Fixed item's expense is never offered — it is From plan
//  already and cannot be moved.
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
}
