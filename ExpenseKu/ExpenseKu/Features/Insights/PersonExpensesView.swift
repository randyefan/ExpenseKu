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

struct PersonExpensesView: View {
    let route: PersonExpensesRoute

    @Environment(\.modelContext) private var context

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

    var body: some View {
        let person = route.person(in: context)
        let category = route.category(in: context)
        let account = route.account(in: context)
        let listed = person.map {
            PeopleLeaderboard.expenses(
                for: $0,
                from: expenses,
                category: category,
                account: account,
                dateRange: route.range.range(payday: Payday.current)
            )
        } ?? []
        let filterSummary = Self.filterSummary(category: category, account: account)

        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                if let person {
                    PersonSpendHeader(
                        name: person.name,
                        total: listed.reduce(0) { $0 + $1.amount },
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
                            message: Self.emptyMessage(
                                name: person.name,
                                filterSummary: filterSummary,
                                range: route.range
                            )
                        )
                        .frame(minHeight: 320)
                    } else {
                        ForEach(listed) { expense in
                            PersonExpenseCard(expense: expense)
                        }

                        Text("Each shared expense credits \(person.name) the full amount.")
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                } else {
                    EmptyStateView(
                        title: "Person Removed",
                        systemImage: "person.slash",
                        message: "This person was deleted, so there is nothing left to show here."
                    )
                    .frame(minHeight: 320)
                }
            }
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .navigationTitle(person?.name ?? "Person")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "Food · Cash" when narrowed, nil when neither category nor account is set.
    static func filterSummary(category: Category?, account: Account?) -> String? {
        let parts = [category?.name, account?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func emptyMessage(name: String, filterSummary: String?, range: DateRangeFilter) -> String {
        if let filterSummary {
            return "\(name) has no expenses matching \(filterSummary) in \(range.label.lowercased())."
        }
        return "\(name) has no expenses in \(range.label.lowercased())."
    }
}
