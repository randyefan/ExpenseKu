//
//  LeaderboardRanking.swift
//  ExpenseKu
//
//  Owns the date-bounded fetch behind the People leaderboard rows. Split out from
//  PeopleLeaderboardView because a `@Query` predicate is fixed at init: a new period
//  means a new instance, which `.id(...)` at the call site guarantees.
//
//  Category and account narrowing stays in the pure PeopleLeaderboard layer.
//

import SwiftUI
import SwiftData

struct LeaderboardRanking: View {
    let range: DateRangeFilter
    let category: Category?
    let account: Account?

    @Query private var expenses: [Expense]

    init(range: DateRangeFilter, category: Category?, account: Account?) {
        self.range = range
        self.category = category
        self.account = account
        let window = range.range(payday: Payday.current)
        let lower = window?.lowerBound ?? .distantPast
        let upper = window?.upperBound ?? .distantFuture
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= lower && $0.date <= upper }
        )
    }

    var body: some View {
        let ranked = PeopleLeaderboard.ranked(
            from: expenses,
            category: category,
            account: account,
            dateRange: range.range(payday: Payday.current)
        )

        if ranked.isEmpty {
            EmptyStateView(
                title: "No People Yet",
                systemImage: "person.2",
                message: "Tag expenses with the people you were with to see who you spend the most with."
            )
            .frame(minHeight: 360)
        } else {
            ForEach(ranked.enumerated(), id: \.element.id) { index, entry in
                NavigationLink(value: InsightsView.Destination.personExpenses(
                    PersonExpensesRoute(
                        person: entry.person,
                        category: category,
                        account: account,
                        range: range
                    )
                )) {
                    LeaderboardRankRow(rank: index + 1, entry: entry)
                }
                .buttonStyle(.plain)
            }

            Text("Totals may exceed your grand total as each companion is credited the full shared amount.")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }
}
