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
nonisolated struct CategorySpend: Identifiable {
    let categoryName: String
    let total: Decimal
    var id: String { categoryName }
}

/// Total spend for one account (or the "Unassigned" bucket).
nonisolated struct AccountSpend: Identifiable {
    let accountName: String
    let total: Decimal
    var id: String { accountName }
}

/// Total spend within one time bucket, keyed by the bucket's start date.
nonisolated struct PeriodSpend: Identifiable {
    let date: Date
    let total: Decimal
    var id: Date { date }
}

nonisolated enum SpendGranularity {
    case day
    case month
    case payPeriod(payday: Int)
}

nonisolated enum SpendSummary {
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

    /// Spend grouped by account, highest first. Expenses with no account — never
    /// set, or left behind by account deletion — fall into an "Unassigned" bucket.
    static func byAccount(
        from expenses: [Expense],
        dateRange: ClosedRange<Date>? = nil
    ) -> [AccountSpend] {
        var totals: [String: Decimal] = [:]
        for expense in expenses {
            if let dateRange, !dateRange.contains(expense.date) { continue }
            let name = expense.account?.name ?? "Unassigned"
            totals[name, default: 0] += expense.amount
        }
        return totals
            .map { AccountSpend(accountName: $0.key, total: $0.value) }
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

    /// The `cycles` most recent pay cycles, oldest first, ending with the one
    /// containing `now`.
    static func payPeriodWindow(
        cycles: Int,
        payday: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PayCycle] {
        guard cycles > 0 else { return [] }
        var window: [PayCycle] = []
        var cycle = PayCycle.containing(now, payday: payday, calendar: calendar)
        for _ in 0..<cycles {
            window.append(cycle)
            cycle = cycle.previous(payday: payday, calendar: calendar)
        }
        return window.reversed()
    }

    /// The bucket key a pay cycle charts under: the start of the month it *ends* in,
    /// the same convention `PayCycle.title` names it by.
    static func payPeriodKey(of cycle: PayCycle, calendar: Calendar = .current) -> Date {
        let lastDay = cycle.lastDay(calendar: calendar)
        return calendar.dateInterval(of: .month, for: lastDay)?.start ?? lastDay
    }

    /// Spend per cycle across `window`, ascending, zero-filled so the run of periods
    /// stays continuous and the current one is always the last entry. Cycles before the
    /// first with any spend are dropped, and an entirely empty window returns nothing so
    /// the caller can show its empty state rather than a row of flat bars.
    static func byPayPeriod(
        from expenses: [Expense],
        window: [PayCycle],
        calendar: Calendar = .current
    ) -> [PeriodSpend] {
        guard !window.isEmpty else { return [] }

        var totals: [Date: Decimal] = [:]
        for expense in expenses {
            guard let cycle = window.first(where: { $0.contains(expense.date) }) else { continue }
            totals[payPeriodKey(of: cycle, calendar: calendar), default: 0] += expense.amount
        }

        let filled = window.map { cycle -> PeriodSpend in
            let key = payPeriodKey(of: cycle, calendar: calendar)
            return PeriodSpend(date: key, total: totals[key] ?? 0)
        }
        guard let firstWithSpend = filled.firstIndex(where: { $0.total > 0 }) else { return [] }
        return Array(filled[firstWithSpend...])
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
        case .payPeriod(let payday):
            return payPeriodKey(
                of: PayCycle.containing(date, payday: payday, calendar: calendar),
                calendar: calendar
            )
        }
    }
}
