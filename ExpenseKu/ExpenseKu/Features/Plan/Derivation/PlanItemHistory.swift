//
//  PlanItemHistory.swift
//  ExpenseKu
//
//  The hint under the amount in the plan item editor: "was Rp 6.751.000 in February,
//  Rp 4.700.000 in August" (frame F1).
//
//  Fixed amounts drift, and that is the reason the whole plan-vs-actual idea exists —
//  `Tagihan Handphone Ibu` was planned at Rp 280.000 and billed at Rp 407.500. When
//  the owner is adjusting a carried-over amount, what it has actually been is the
//  most useful thing on the screen.
//
//  Matching is on the normalised name, the same key `existingEntity` uses, so
//  renaming an item does not break its trail.
//

import Foundation
import SwiftData

nonisolated enum PlanItemHistory {
    /// The two most recent cycles in which a differently-sized amount was actually
    /// paid, most recent first. Nil when there is nothing to say — a first plan, or a
    /// line that has never moved.
    static func hint(for name: String, excluding current: CyclePlan?, in plans: [CyclePlan],
                     calendar: Calendar = .current) -> String? {
        let key = NameKey.normalized(name)
        guard !key.isEmpty else { return nil }

        let actuals = plans
            .filter { $0.persistentModelID != current?.persistentModelID }
            .sorted { $0.cycleStart > $1.cycleStart }
            .compactMap { plan -> (Date, Decimal)? in
                guard let item = (plan.items ?? []).first(where: { NameKey.normalized($0.name) == key }),
                      let expense = item.linkedExpense else { return nil }
                return (plan.cycleStart, expense.amount)
            }

        // One figure that never varied says nothing worth a line of screen.
        let distinct = Set(actuals.map(\.1))
        guard actuals.count > 1 || distinct.count > 1 else { return nil }

        let phrases = actuals.prefix(2).map { start, amount in
            "\(amount.formattedIDR()) in \(start.formatted(.dateTime.month(.wide)))"
        }
        return "was " + phrases.joined(separator: ", ")
    }
}
