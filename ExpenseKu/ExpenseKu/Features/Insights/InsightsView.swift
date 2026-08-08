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
    @Query private var expenses: [Expense]
    @State private var range: DateRangeFilter = .thisYear

    private var byCategory: [CategorySpend] {
        SpendSummary.byCategory(from: expenses, dateRange: range.range())
    }

    private var overTime: [PeriodSpend] {
        SpendSummary.overTime(from: expenses, dateRange: range.range(), granularity: .month)
    }

    var body: some View {
        NavigationStack {
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

                Section("Spend over Time") {
                    if overTime.isEmpty {
                        Text("No spending in this period.")
                            .foregroundStyle(.secondary)
                    } else {
                        SpendOverTimeChart(data: overTime, granularity: .month)
                    }
                }

                Section {
                    NavigationLink {
                        PeopleLeaderboardView()
                    } label: {
                        Label("Who you spend with", systemImage: "person.2")
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }
}
