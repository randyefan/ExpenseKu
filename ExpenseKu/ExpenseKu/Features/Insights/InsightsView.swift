//
//  InsightsView.swift
//  ExpenseKu
//
//  The Insights tab: spend-by-category and spend-over-time charts over a shared
//  period filter, plus a link to the People leaderboard. Aggregation lives in
//  the pure SpendSummary / PeopleLeaderboard layers.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    enum Destination: Hashable { case leaderboard }

    @Query private var expenses: [Expense]
    @State private var range: DateRangeFilter = .thisYear
    @State private var path: [Destination] = []

    private var byCategory: [CategorySpend] {
        SpendSummary.byCategory(from: expenses, dateRange: range.range())
    }

    private var overTime: [PeriodSpend] {
        SpendSummary.overTime(from: expenses, dateRange: range.range(), granularity: .month)
    }

    private var byAccount: [AccountSpend] {
        SpendSummary.byAccount(from: expenses, dateRange: range.range())
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Picker("Period", selection: $range) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                }

                Section("Spend by Category") {
                    if byCategory.isEmpty {
                        Text("No spending in this period.")
                            .foregroundStyle(.secondary)
                    } else {
                        SpendByCategoryChart(data: byCategory)
                    }
                }

                Section("Spend by Account") {
                    if byAccount.isEmpty {
                        Text("No spending in this period.")
                            .foregroundStyle(.secondary)
                    } else {
                        SpendByAccountChart(data: byAccount)
                    }
                }

                Section("Spend over Time") {
                    if overTime.isEmpty {
                        Text("No spending in this period.")
                            .foregroundStyle(.secondary)
                    } else {
                        SpendOverTimeChart(data: overTime, granularity: .month)
                    }
                }

                Section {
                    NavigationLink(value: Destination.leaderboard) {
                        Label("Who you spend with", systemImage: "person.2")
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationDestination(for: Destination.self) { _ in
                PeopleLeaderboardView()
            }
        }
        .task {
            #if DEBUG
            if DebugLaunch.startScreen == "leaderboard" { path = [.leaderboard] }
            #endif
        }
    }
}
