//
//  InsightsCharts.swift
//  ExpenseKu
//
//  Owns the date-bounded fetch behind the three Insights charts. Split out from
//  InsightsView because a `@Query` predicate is fixed at init: a new range means a new
//  instance, which `.id(...)` at the call site guarantees.
//
//  The aggregation stays in the pure SpendSummary layer — only the fetch narrows.
//

import SwiftUI
import SwiftData

struct InsightsCharts: View {
    let dateRange: ClosedRange<Date>?

    @Query private var expenses: [Expense]

    init(dateRange: ClosedRange<Date>?) {
        self.dateRange = dateRange
        let lower = dateRange?.lowerBound ?? .distantPast
        let upper = dateRange?.upperBound ?? .distantFuture
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= lower && $0.date <= upper }
        )
    }

    var body: some View {
        let byCategory = SpendSummary.byCategory(from: expenses, dateRange: dateRange)
        let byAccount = SpendSummary.byAccount(from: expenses, dateRange: dateRange)
        let overTime = SpendSummary.overTime(from: expenses, dateRange: dateRange, granularity: .month)

        Group {
            ChartCard("Spend by Category") {
                if byCategory.isEmpty {
                    EmptyChartMessage()
                } else {
                    SpendByCategoryChart(data: byCategory)
                }
            }

            ChartCard("Spend by Account") {
                if byAccount.isEmpty {
                    EmptyChartMessage()
                } else {
                    SpendByAccountChart(data: byAccount)
                }
            }

            ChartCard(title: "Spend over Time", accessory: { ByMonthTag() }) {
                if overTime.isEmpty {
                    EmptyChartMessage()
                } else {
                    SpendOverTimeChart(data: overTime, granularity: .month)
                }
            }
        }
    }
}
