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

    private var ranked: [PersonSpend] {
        PeopleLeaderboard.ranked(
            from: expenses,
            category: categoryFilter,
            account: accountFilter,
            dateRange: rangeFilter.range(payday: Payday.current)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                Text("Who you spend with")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)

                filters

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
                            rankRow(index: index, entry: entry)
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

    // MARK: - Filters

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Period", selection: $rangeFilter) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    filterChip("Period", value: rangeFilter.label)
                }

                Menu {
                    Button("All") { categoryFilter = nil }
                    Divider()
                    ForEach(categories) { category in
                        Button(category.name) { categoryFilter = category }
                    }
                } label: {
                    filterChip("Category", value: categoryFilter?.name ?? "All")
                }

                Menu {
                    Button("All") { accountFilter = nil }
                    Divider()
                    ForEach(accounts) { account in
                        Button(account.name) { accountFilter = account }
                    }
                } label: {
                    filterChip("Account", value: accountFilter?.name ?? "All")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label): \(value)")
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
            Image(systemName: "chevron.down")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Theme.card)
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
    }

    // MARK: - Row

    private func rankRow(index: Int, entry: PersonSpend) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.dsBody).fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(index == 0 ? Theme.accent : Theme.textSecondary)
                .frame(minWidth: 20, alignment: .center)

            PersonAvatar(name: entry.person.name, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.person.name)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                Text("^[\(entry.sharedCount) expense](inflect: true)")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 8)

            MoneyText(entry.total, font: .dsBody, color: Theme.text)

            Image(systemName: "chevron.right")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }
}
