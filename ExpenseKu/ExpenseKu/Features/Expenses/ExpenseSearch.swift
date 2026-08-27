//
//  ExpenseSearch.swift
//  ExpenseKu
//
//  Everything the Expenses tab derives from one search query: the matching
//  expenses newest-first and their total. Unlike CycleContents this deliberately
//  ignores the pay cycle — search looks at every expense ever logged, which is
//  the whole point of it. Pure, so it can be unit-tested without a
//  ModelContainer — the same shape as the CycleContents / SpendSummary layers.
//

import Foundation

/// How a query is compared against an expense.
nonisolated enum ExpenseSearchMatch {
    /// Case- and diacritic-folded, so "cafe" finds "Café" and "KOPI" finds "kopi".
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// The query split into the terms that must *all* match.
    static func tokens(_ query: String) -> [String] {
        fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
    }

    /// The searchable text of an expense: its note plus the names of the things
    /// it points at. Missing relationships contribute nothing — "Uncategorized"
    /// is how the UI renders a nil category, not something the owner typed.
    static func haystack(_ expense: Expense) -> String {
        var parts = [expense.note]
        if let name = expense.category?.name { parts.append(name) }
        parts.append(contentsOf: (expense.people ?? []).map(\.name))
        if let name = expense.account?.name { parts.append(name) }
        return fold(parts.joined(separator: " "))
    }

    /// Every token must appear somewhere in the expense's searchable text, so a
    /// multi-word query narrows across fields ("kopi cash") rather than needing
    /// one field to contain the whole phrase. No tokens means no match: an empty
    /// query is "nothing", never "everything".
    static func matches(_ expense: Expense, tokens: [String]) -> Bool {
        guard !tokens.isEmpty else { return false }
        let text = haystack(expense)
        return tokens.allSatisfy { text.contains($0) }
    }
}

nonisolated struct ExpenseSearchResults {
    /// The matches, ordered newest first.
    let expenses: [Expense]
    /// Sum of the matches' amounts — the total shown above the results.
    let total: Decimal

    var count: Int { expenses.count }
    var isEmpty: Bool { expenses.isEmpty }

    /// - Parameters:
    ///   - categoryName: restrict to one category by name, or nil for all. A name
    ///     rather than a `Category` so this layer never holds a live model.
    ///   - dateRange: restrict to a window, inclusive at both ends, or nil for all time.
    init(
        query: String,
        allExpenses: [Expense],
        categoryName: String? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) {
        let tokens = ExpenseSearchMatch.tokens(query)
        let matched = allExpenses.filter { expense in
            guard ExpenseSearchMatch.matches(expense, tokens: tokens) else { return false }
            if let categoryName, expense.category?.name != categoryName { return false }
            if let dateRange, !dateRange.contains(expense.date) { return false }
            return true
        }
        // Sorted here rather than inherited from the caller's @Query order, so the
        // ordering is this layer's promise and the tests can pin it.
        self.expenses = matched.sorted { $0.date > $1.date }
        self.total = matched.reduce(Decimal(0)) { $0 + $1.amount }
    }
}
