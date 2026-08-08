//
//  SpendOverTimeChart.swift
//  ExpenseKu
//
//  Bar chart of spend bucketed over time. Pure presentation — handed
//  already-aggregated data from SpendSummary.
//

import SwiftUI
import Charts

struct SpendOverTimeChart: View {
    let data: [PeriodSpend]
    let granularity: SpendGranularity

    private var calendarUnit: Calendar.Component {
        granularity == .month ? .month : .day
    }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Period", item.date, unit: calendarUnit),
                y: .value("Amount", item.total.doubleValue)
            )
        }
        .frame(height: 200)
    }
}
