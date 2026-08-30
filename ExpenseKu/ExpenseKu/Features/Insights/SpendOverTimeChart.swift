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
    var currentPeriod: Date? = nil

    private var calendarUnit: Calendar.Component {
        switch granularity {
        case .day: .day
        case .month, .payPeriod: .month
        }
    }

    private var labelFormat: Date.FormatStyle {
        switch granularity {
        case .day: .dateTime.day()
        case .month, .payPeriod: .dateTime.month(.abbreviated)
        }
    }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Period", item.date, unit: calendarUnit),
                y: .value("Amount", item.total.doubleValue),
                width: .ratio(0.6)
            )
            // The period you are in now is coral; the rest charcoal. Axis labels carry
            // the meaning, so colour is decorative only.
            .foregroundStyle(item.date == currentPeriod ? Theme.accent : Theme.textSecondary.opacity(0.5))
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
