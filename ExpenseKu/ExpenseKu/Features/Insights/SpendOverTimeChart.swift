//
//  SpendOverTimeChart.swift
//  ExpenseKu
//
//  Bar chart of spend bucketed over time. Pure presentation — handed
//  already-aggregated data from SpendSummary.
//
//  This is the one chart where amber still means something: the period you are
//  standing in. The rest stay neutral so the current one reads at a glance, and
//  every period that has spend carries its own value above the bar, so a period
//  can be read without counting gridlines and the current one is never colour-only.
//
//  Labels are given the width of one bar slot and allowed to shrink into it, so a
//  full window of twelve pay periods never collides.
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
        GeometryReader { proxy in
            chart(slotWidth: proxy.size.width / CGFloat(max(data.count, 1)))
        }
        .frame(height: 180)
        .growsOnAppear(growth, trigger: data.map(\.id))
    }

    private func chart(slotWidth: CGFloat) -> some View {
        Chart(data) { item in
            BarMark(
                x: .value("Period", item.date, unit: calendarUnit),
                y: .value("Amount", item.total.doubleValue * growth.factor),
                width: .ratio(0.55)
            )
            .foregroundStyle(item.date == currentPeriod ? Theme.accent : Theme.textSecondary.opacity(0.45))
            .cornerRadius(6)
            .annotation(position: .top, alignment: .center, spacing: 3) {
                valueLabel(for: item, slotWidth: slotWidth)
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
    }

    @ViewBuilder
    private func valueLabel(for item: PeriodSpend, slotWidth: CGFloat) -> some View {
        if item.total > 0 {
            let isCurrent = item.date == currentPeriod
            Text(item.total.compactAmount())
                .font(.dsCaption)
                .fontWeight(isCurrent ? .semibold : .regular)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isCurrent ? Theme.accentText : Theme.textSecondary)
                .frame(width: max(slotWidth - 2, 1))
                .opacity(growth.factor)
        }
    }
}
