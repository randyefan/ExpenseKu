//
//  InsightsCharts.swift
//  ExpenseKu
//
//  Owns the date-bounded fetch behind the SPENDING card and the three Insights charts.
//  Split out from InsightsView because a `@Query` predicate is fixed at init: a new
//  range means a new instance, which `.id(...)` at the call site guarantees.
//
//  Spend over Time deliberately ignores the period filter and fetches its own window of
//  pay cycles: bounded to one period it would only ever draw a single bar, and none at
//  all before the first expense of the cycle lands. It does follow the plan filter, each
//  bar judged by its own cycle's plan (docs/prd/insights-drill-in.md §6.2).
//
//  The aggregation stays in the pure SpendSummary and PlanOrigins layers.
//

import SwiftUI
import SwiftData

struct InsightsCharts: View {
    let dateRange: ClosedRange<Date>?
    let payday: Int
    /// The cycle Spend over Time marks in amber.
    let highlightedCycle: PayCycle
    let origins: PlanOrigins
    @Binding var planFilter: PlanFilter?
    let onSelect: (SpendSubject) -> Void

    static let trendCycles = 12

    @Query private var expenses: [Expense]
    @Query private var trendExpenses: [Expense]

    private let trendWindow: [PayCycle]

    init(
        dateRange: ClosedRange<Date>?,
        payday: Int,
        highlightedCycle: PayCycle,
        origins: PlanOrigins,
        planFilter: Binding<PlanFilter?>,
        onSelect: @escaping (SpendSubject) -> Void
    ) {
        self.dateRange = dateRange
        self.payday = payday
        self.highlightedCycle = highlightedCycle
        self.origins = origins
        _planFilter = planFilter
        self.onSelect = onSelect
        let lower = dateRange?.lowerBound ?? .distantPast
        let upper = dateRange?.upperBound ?? .distantFuture
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= lower && $0.date <= upper }
        )

        let window = PayPeriodChoices.trendWindow(count: Self.trendCycles, selected: highlightedCycle, payday: payday)
        trendWindow = window
        let trendStart = window.first?.start ?? .distantPast
        let trendEnd = window.last?.end ?? .distantFuture
        _trendExpenses = Query(
            filter: #Predicate<Expense> { $0.date >= trendStart && $0.date < trendEnd }
        )
    }

    var body: some View {
        let split = origins.split(expenses)
        let shown = planFilter.map { origins.expenses(expenses, matching: $0) } ?? expenses
        let shownTrend = planFilter.map { origins.expenses(trendExpenses, matching: $0) } ?? trendExpenses
        let byCategory = SpendSummary.byCategory(from: shown, dateRange: dateRange)
        let byAccount = SpendSummary.byAccount(from: shown, dateRange: dateRange)
        let granularity = SpendGranularity.payPeriod(payday: payday)
        let overTime = SpendSummary.byPayPeriod(from: shownTrend, window: trendWindow)
        let emptyMessage = planFilter?.emptyPeriodMessage ?? EmptyChartMessage().message

        Group {
            InsightsSpendingCard(split: split, filter: planFilter) { half in
                planFilter = PlanFilter.tapping(half, on: planFilter)
            }
            .reveal(1, trigger: dateRange)

            ChartCard("Spend by Category") {
                if byCategory.isEmpty {
                    EmptyChartMessage(message: emptyMessage)
                } else {
                    SpendByCategoryChart(data: byCategory, onSelect: onSelect)
                }
            }
            .reveal(2, trigger: dateRange)

            ChartCard("Spend by Account") {
                if byAccount.isEmpty {
                    EmptyChartMessage(message: emptyMessage)
                } else {
                    SpendByAccountChart(data: byAccount, onSelect: onSelect)
                }
            }
            .reveal(3, trigger: dateRange)

            ChartCard(title: "Spend over Time", accessory: { ByPayPeriodTag() }) {
                if overTime.isEmpty {
                    EmptyChartMessage(message: emptyMessage)
                } else {
                    SpendOverTimeChart(
                        data: overTime,
                        granularity: granularity,
                        currentPeriod: SpendSummary.payPeriodKey(of: highlightedCycle)
                    )
                }
            }
            .reveal(4, trigger: dateRange)
        }
    }
}
