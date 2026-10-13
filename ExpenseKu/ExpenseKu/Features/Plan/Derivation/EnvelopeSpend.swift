//
//  EnvelopeSpend.swift
//  ExpenseKu
//
//  What an envelope has actually absorbed, derived from expenses the owner already
//  logged (PRD §5.2). This is the single biggest improvement over the spreadsheet,
//  where that column was totalled by hand at the end of a cycle; here it is live.
//
//  Which envelope an expense counts in is `EnvelopeClaims`' job — an assignment by
//  hand, else its Category, never a Fixed item's expense (envelope-assignment.md §4.1).
//  Without that last exclusion a completed "Kos" is counted a second time inside the
//  "Hidup" envelope that shares its Group, and the plan quietly reports money twice
//  (ADR-0005).
//
//  An expense that lands in no envelope is simply unbudgeted: it counts in the cycle's
//  spending as it always has, and toward no envelope. That is a third way real money
//  escapes Sisa, and it is deliberately unreported (§11.3).
//

import Foundation
import SwiftData

nonisolated enum EnvelopeSpend {
    static func progress(envelopes: [PlanItem], cycleExpenses: [Expense]) -> [EnvelopeProgress] {
        let envelopeClaims = EnvelopeClaims(envelopes: envelopes)
        var spent: [PersistentIdentifier: Decimal] = [:]
        for expense in cycleExpenses {
            guard let envelope = envelopeClaims.envelope(for: expense) else { continue }
            spent[envelope.persistentModelID, default: 0] += expense.amount
        }
        return envelopes.map { envelope in
            EnvelopeProgress(itemID: envelope.persistentModelID,
                             planned: envelope.amount,
                             spent: spent[envelope.persistentModelID] ?? 0)
        }
    }

    /// The categories already claimed by some *other* envelope in this plan, mapped to
    /// the envelope's name, for F4's disabled "already in <name>" rows. A Category
    /// belongs to at most one envelope per plan (§5.2), so two envelopes can never
    /// count the same expense twice — enforced in the picker, because ADR-0002 means
    /// the store cannot carry the constraint itself.
    static func claims(in items: [PlanItem], excluding: PlanItem?) -> [PersistentIdentifier: String] {
        var claimed: [PersistentIdentifier: String] = [:]
        for item in items where item.isEnvelope {
            if let excluding, item.persistentModelID == excluding.persistentModelID { continue }
            for category in item.envelopeCategories ?? [] {
                claimed[category.persistentModelID] = item.name
            }
        }
        return claimed
    }
}

/// One envelope's bar: how full it is, and what the remainder line reads.
nonisolated struct EnvelopeProgress: Identifiable, Equatable {
    let itemID: PersistentIdentifier
    let planned: Decimal
    let spent: Decimal

    var id: PersistentIdentifier { itemID }

    var isOver: Bool { spent > planned }

    /// How much the envelope is over by. Zero when it is not — the plan's drift
    /// figure counts overspend only, because an envelope with room left is unspent
    /// allowance, not underspend, and netting the two would make the figure
    /// meaningless mid-cycle.
    var overspend: Decimal { isOver ? spent - planned : 0 }

    /// Always positive; read it with `isOver` to pick "Rp 226.900 left" or
    /// "Rp 48.300 over".
    var remainder: Decimal { isOver ? spent - planned : planned - spent }

    var remainderText: String { "\(remainder.formattedIDR()) \(isOver ? "over" : "left")" }

    /// Deliberately unclamped — past 1 the bar fills its track and recolours rather
    /// than stopping at full and hiding the overspend. Zero when nothing is planned,
    /// never a division by zero.
    var fraction: Double {
        guard planned > 0 else { return 0 }
        return (spent / planned).doubleValue
    }
}
