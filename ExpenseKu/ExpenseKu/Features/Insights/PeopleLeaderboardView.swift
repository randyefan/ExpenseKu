//
//  PeopleLeaderboardView.swift
//  ExpenseKu
//
//  "Who did I spend the most with." Ranks people by total attributed spend,
//  filterable by category, account and time window. Aggregation lives in the
//  pure PeopleLeaderboard layer; this view only fetches, filters, and renders.
//  Warm Cards styling; behaviour unchanged (full-amount-to-each-companion
//  attribution, so totals may exceed the grand total by design).
//

import SwiftUI
import SwiftData

struct PeopleLeaderboardView: View {
    @Query private var expenses: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var categoryFilter: Category?
    @State private var accountFilter: Account?
    @State private var rangeFilter: DateRangeFilter = .allTime

    var body: some View {
        let ranked = PeopleLeaderboard.ranked(
            from: expenses,
            category: categoryFilter,
            account: accountFilter,
            dateRange: rangeFilter.range(payday: Payday.current)
        )

        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                Text("Who you spend with")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)

                LeaderboardFilters(
                    range: $rangeFilter,
                    category: $categoryFilter,
                    account: $accountFilter,
                    categories: categories,
                    accounts: accounts
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
                                category: categoryFilter,
                                account: accountFilter,
                                range: rangeFilter
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
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .navigationTitle("People leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
