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

    private var maxTotal: Double { data.map(\.total.doubleValue).max() ?? 0 }

    private var labelFormat: Date.FormatStyle {
        granularity == .month ? .dateTime.month(.abbreviated) : .dateTime.day()
    }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Period", item.date, unit: calendarUnit),
                y: .value("Amount", item.total.doubleValue),
                width: .ratio(0.6)
            )
            // The tallest month is coral; the rest charcoal. Axis labels carry
            // the meaning, so colour is decorative only.
            .foregroundStyle(item.total.doubleValue >= maxTotal ? Theme.accent : Theme.textSecondary.opacity(0.5))
            .cornerRadius(6)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: calendarUnit)) { _ in
                AxisValueLabel(format: labelFormat)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(height: 180)
    }
}
