//
//  SpendSummary.swift
//  ExpenseKu
//
//  Pure aggregations behind the Insights charts. UI-free and dependency-free
//  (operate on a plain [Expense]) so they can be unit-tested. Money stays
//  Decimal here; conversion to Double happens only at the chart boundary.
//

import Foundation

/// Total spend for one category (or the "Uncategorized" bucket).
struct CategorySpend: Identifiable {
    let categoryName: String
    let total: Decimal
    var id: String { categoryName }
}

/// Total spend within one time bucket, keyed by the bucket's start date.
struct PeriodSpend: Identifiable {
    let date: Date
    let total: Decimal
    var id: Date { date }
}

enum SpendGranularity {
    case day
    case month
}

enum SpendSummary {
    /// Spend grouped by category, highest first. Expenses whose category was
    /// deleted fall into an "Uncategorized" bucket (ADR-0001).
    static func byCategory(
        from expenses: [Expense],
        dateRange: ClosedRange<Date>? = nil
    ) -> [CategorySpend] {
        var totals: [String: Decimal] = [:]
        for expense in expenses {
            if let dateRange, !dateRange.contains(expense.date) { continue }
            let name = expense.category?.name ?? "Uncategorized"
            totals[name, default: 0] += expense.amount
        }
        return totals
            .map { CategorySpend(categoryName: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    /// Spend bucketed over time (ascending), by day or month.
    static func overTime(
        from expenses: [Expense],
        dateRange: ClosedRange<Date>? = nil,
        granularity: SpendGranularity = .month,
        calendar: Calendar = .current
    ) -> [PeriodSpend] {
        var totals: [Date: Decimal] = [:]
        for expense in expenses {
            if let dateRange, !dateRange.contains(expense.date) { continue }
            let bucket = bucketStart(for: expense.date, granularity: granularity, calendar: calendar)
            totals[bucket, default: 0] += expense.amount
        }
        return totals
            .map { PeriodSpend(date: $0.key, total: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private static func bucketStart(
        for date: Date,
        granularity: SpendGranularity,
        calendar: Calendar
    ) -> Date {
        switch granularity {
        case .day:
            return calendar.startOfDay(for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start ?? date
        }
    }
}
