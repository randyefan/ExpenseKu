//
//  PeopleLeaderboardView.swift
//  ExpenseKu
//
//  "Who did I spend the most with." Ranks people by total attributed spend,
//  filterable by category and time window. Aggregation lives in the pure
//  PeopleLeaderboard layer; this view only fetches, filters, and renders.
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

    private var ranked: [PersonSpend] {
        PeopleLeaderboard.ranked(
            from: expenses,
            category: categoryFilter,
            account: accountFilter,
            dateRange: rangeFilter.range(payday: Payday.current)
        )
    }

    var body: some View {
        List {
            Section {
                Picker("Period", selection: $rangeFilter) {
                    ForEach(DateRangeFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                Menu {
                    Button("All Categories") { categoryFilter = nil }
                    Divider()
                    ForEach(categories) { category in
                        Button(category.name) { categoryFilter = category }
                    }
                } label: {
                    LabeledContent("Category", value: categoryFilter?.name ?? "All")
                }
                Menu {
                    Button("All Accounts") { accountFilter = nil }
                    Divider()
                    ForEach(accounts) { account in
                        Button(account.name) { accountFilter = account }
                    }
                } label: {
                    LabeledContent("Account", value: accountFilter?.name ?? "All")
                }
            }

            Section("Ranked by spend") {
                ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(minWidth: 24, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.person.name)
                            Text("^[\(entry.sharedCount) expense](inflect: true)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.total.formattedIDR())
                            .monospacedDigit()
                    }
                }
            }
        }
        .overlay {
            if ranked.isEmpty {
                ContentUnavailableView(
                    "No People Yet",
                    systemImage: "person.2",
                    description: Text("Tag expenses with the people you were with to see who you spend the most with.")
                )
            }
        }
        .navigationTitle("People")
    }
}
