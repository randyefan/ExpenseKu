//
//  SpendOverTimeChart.swift
//  ExpenseKu
//
//  Bar chart of spend bucketed over time. Pure presentation — handed
//  already-aggregated data from SpendSummary.
//
//  This is the one chart where amber still means something: the period you are
//  standing in. The rest stay neutral so the current one reads at a glance, and
//  its value is called out above the bar so the meaning is never colour-only.
//

import SwiftUI
import Charts

struct SpendOverTimeChart: View {
    let data: [PeriodSpend]
    let granularity: SpendGranularity
    var currentPeriod: Date? = nil

    @State private var growth = ChartGrowth()

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

    private var maxTotal: Double { data.map(\.total.doubleValue).max() ?? 1 }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Period", item.date, unit: calendarUnit),
                y: .value("Amount", item.total.doubleValue * growth.factor),
                width: .ratio(0.55)
            )
            .foregroundStyle(item.date == currentPeriod ? Theme.accent : Theme.textSecondary.opacity(0.45))
            .cornerRadius(6)
            .annotation(position: .top, alignment: .center) {
                if item.date == currentPeriod, item.total > 0 {
                    Text(item.total.compactIDR())
                        .font(.dsCaption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Theme.accentText)
                        .opacity(growth.factor)
                }
            }
        }
        .chartYScale(domain: 0...maxTotal * 1.18)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: calendarUnit)) { _ in
                AxisValueLabel(format: labelFormat)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(height: 180)
        .growsOnAppear(growth, trigger: data.map(\.id))
    }
}
