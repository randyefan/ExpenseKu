//
//  InsightsCharts.swift
//  ExpenseKu
//
//  Owns the date-bounded fetch behind the three Insights charts. Split out from
//  InsightsView because a `@Query` predicate is fixed at init: a new range means a new
//  instance, which `.id(...)` at the call site guarantees.
//
//  Spend over Time deliberately ignores the period filter and fetches its own window of
//  recent pay cycles: bounded to one period it would only ever draw a single bar, and
//  none at all before the first expense of the cycle lands.
//
//  The aggregation stays in the pure SpendSummary layer — only the fetch narrows.
//

import SwiftUI
import SwiftData

struct InsightsCharts: View {
    let dateRange: ClosedRange<Date>?
    let payday: Int

    static let trendCycles = 12

    @Query private var expenses: [Expense]
    @Query private var trendExpenses: [Expense]

    private let trendWindow: [PayCycle]

    init(dateRange: ClosedRange<Date>?, payday: Int) {
        self.dateRange = dateRange
        self.payday = payday
        let lower = dateRange?.lowerBound ?? .distantPast
        let upper = dateRange?.upperBound ?? .distantFuture
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= lower && $0.date <= upper }
        )

        let window = SpendSummary.payPeriodWindow(cycles: Self.trendCycles, payday: payday)
        trendWindow = window
        let trendStart = window.first?.start ?? .distantPast
        let trendEnd = window.last?.end ?? .distantFuture
        _trendExpenses = Query(
            filter: #Predicate<Expense> { $0.date >= trendStart && $0.date < trendEnd }
        )
    }

    var body: some View {
        let byCategory = SpendSummary.byCategory(from: expenses, dateRange: dateRange)
        let byAccount = SpendSummary.byAccount(from: expenses, dateRange: dateRange)
        let granularity = SpendGranularity.payPeriod(payday: payday)
        let overTime = SpendSummary.byPayPeriod(from: trendExpenses, window: trendWindow)
        let currentPeriod = trendWindow.last.map { SpendSummary.payPeriodKey(of: $0) }

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

            ChartCard(title: "Spend over Time", accessory: { ByPayPeriodTag() }) {
                if overTime.isEmpty {
                    EmptyChartMessage()
                } else {
                    SpendOverTimeChart(
                        data: overTime,
                        granularity: granularity,
                        currentPeriod: currentPeriod
                    )
                }
            }
        }
    }
}
