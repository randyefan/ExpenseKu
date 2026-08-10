//
//  PeopleLeaderboard.swift
//  ExpenseKu
//
//  Pure aggregation for "who did I spend the most with." UI-free and dependency-
//  free (operates on a plain [Expense]) so it can be unit-tested without a view
//  or a live ModelContext.
//
//  Attribution rule (design.md §5 / CONTEXT.md): the FULL amount is credited to
//  each companion on an expense. A 100k expense tagged with two people counts
//  100k toward each — a per-person ranking, not a sum, so totals may exceed the
//  grand total by design. Nothing is stored; this is computed on the fly.
//

import Foundation
import SwiftData

/// One row of the leaderboard: a person, their total attributed spend, and how
/// many expenses they were tagged on (within the active filters).
struct PersonSpend: Identifiable {
    let person: Person
    let total: Decimal
    let sharedCount: Int
    var id: PersistentIdentifier { person.persistentModelID }
}

enum PeopleLeaderboard {
    /// Ranks people by total attributed spend (desc), tie-broken by name (asc).
    ///
    /// - Parameters:
    ///   - expenses: the expenses to aggregate.
    ///   - category: when set, only expenses in this category are counted.
    ///   - account: when set, only expenses paid from this account are counted.
    ///   - dateRange: when set, only expenses whose date falls inside are counted.
    static func ranked(
        from expenses: [Expense],
        category: Category? = nil,
        account: Account? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) -> [PersonSpend] {
        var totals: [PersistentIdentifier: (person: Person, total: Decimal, count: Int)] = [:]

        for expense in expenses {
            if let category, expense.category?.persistentModelID != category.persistentModelID {
                continue
            }
            if let account, expense.account?.persistentModelID != account.persistentModelID {
                continue
            }
            if let dateRange, !dateRange.contains(expense.date) {
                continue
            }
            guard let people = expense.people, !people.isEmpty else { continue }

            for person in people {
                // The owner ("Me") is on nearly every expense; a companion ranking
                // that always leads with yourself is noise, so skip it.
                if person.isMe { continue }
                let id = person.persistentModelID
                var entry = totals[id] ?? (person: person, total: 0, count: 0)
                entry.total += expense.amount   // full amount to each companion
                entry.count += 1
                totals[id] = entry
            }
        }

        return totals.values
            .map { PersonSpend(person: $0.person, total: $0.total, sharedCount: $0.count) }
            .sorted { lhs, rhs in
                if lhs.total != rhs.total { return lhs.total > rhs.total }
                return lhs.person.name.localizedCaseInsensitiveCompare(rhs.person.name) == .orderedAscending
            }
    }
}
