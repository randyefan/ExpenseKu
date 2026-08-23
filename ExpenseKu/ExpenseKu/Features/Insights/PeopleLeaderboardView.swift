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
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var categoryFilter: Category?
    @State private var accountFilter: Account?
    @State private var rangeFilter: DateRangeFilter = .allTime

    var body: some View {
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

                // Re-created whenever the window changes, because @Query fixes its
                // predicate at init.
                LeaderboardRanking(
                    range: rangeFilter,
                    category: categoryFilter,
                    account: accountFilter
                )
                .id(rangeFilter)
            }
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .navigationTitle("People leaderboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
