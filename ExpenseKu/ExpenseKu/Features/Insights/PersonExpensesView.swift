//
//  PersonExpensesView.swift
//  ExpenseKu
//
//  The drill-down behind a People-leaderboard row: "which expenses make up my
//  total with this person." Pushed onto the Insights nav stack, carrying the
//  leaderboard's active Period / Category / Account filters so the numbers match
//  the row you tapped. Display-only; aggregation lives in the pure
//  PeopleLeaderboard layer. Warm Cards styling, behaviour unchanged (full amount
//  credited to each companion, so the total mirrors the row exactly).
//

import SwiftUI
import SwiftData

/// What a leaderboard row hands to the detail screen: the person plus the filters
/// that were active when it was tapped. All members are Hashable, so this is a
/// valid `NavigationStack` path value.
struct PersonExpensesRoute: Hashable {
    let person: Person
    let category: Category?
    let account: Account?
    let range: DateRangeFilter
}

struct PersonExpensesView: View {
    let route: PersonExpensesRoute

    /// Bounded by the route's date range so the store returns only rows this screen can
    /// show. Category and person narrowing stays in the pure PeopleLeaderboard layer —
    /// only the date bound is cheap and safe to express as a predicate.
    @Query private var expenses: [Expense]

    init(route: PersonExpensesRoute) {
        self.route = route
        // Bound to plain values before the macro sees them: a predicate that evaluates
        // an optional or a computed property compiles clean and traps at runtime.
        let range = route.range.range(payday: Payday.current)
        let lower = range?.lowerBound ?? .distantPast
        let upper = range?.upperBound ?? .distantFuture
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= lower && $0.date <= upper },
            sort: \Expense.date,
            order: .reverse
        )
    }

    private var listed: [Expense] {
        PeopleLeaderboard.expenses(
            for: route.person,
            from: expenses,
            category: route.category,
            account: route.account,
            dateRange: route.range.range(payday: Payday.current)
        )
    }

    private var total: Decimal { listed.reduce(0) { $0 + $1.amount } }

    /// "Food · Cash" when narrowed, nil when neither category nor account is set.
    private var filterSummary: String? {
        let parts = [route.category?.name, route.account?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                PersonSpendHeader(
                    name: route.person.name,
                    total: total,
                    count: listed.count,
                    rangeLabel: route.range.label
                )

                if let filterSummary {
                    Text("Filtered by \(filterSummary)")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 2)
                }

                if listed.isEmpty {
                    EmptyStateView(
                        title: "No Expenses in Range",
                        systemImage: "person.2.slash",
                        message: emptyMessage
                    )
                    .frame(minHeight: 320)
                } else {
                    ForEach(listed) { expense in
                        PersonExpenseCard(expense: expense)
                    }

                    Text("Each shared expense credits \(route.person.name) the full amount.")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .navigationTitle(route.person.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyMessage: String {
        if let filterSummary {
            return "\(route.person.name) has no expenses matching \(filterSummary) in \(route.range.label.lowercased())."
        }
        return "\(route.person.name) has no expenses in \(route.range.label.lowercased())."
    }
}
