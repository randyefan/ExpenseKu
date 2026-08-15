//
//  CycleCalendar.swift
//  ExpenseKu
//
//  Pure projection of a pay cycle onto a month-style grid — the behaviour oracle
//  for the calendar view of the Expenses tab (see .scratch/features/expense-calendar/).
//  The grid is *cycle*-aligned, not month-aligned (ADR-0004 keeps the pay cycle as the
//  home screen's lens), so it spans whole weeks around [cycle.start, cycle.lastDay]
//  and marks anything outside the cycle as filler. Day totals come from
//  `expenseDayGroups` so the grid and the list can never disagree about a day.
//  No SwiftUI, no side effects — unit-testable.
//

import Foundation

/// One cell in the grid: a calendar day, whether the cycle owns it, and its spend.
struct CalendarDay: Identifiable, Equatable {
    /// Start of the day this cell represents.
    let date: Date
    /// False for the leading/trailing filler days that only exist to square off the
    /// weeks. Filler is greyed and not tappable, and always carries zero spend.
    let inCycle: Bool
    /// Sum of the day's expense amounts. Always 0 for filler days.
    let total: Decimal
    /// Number of expenses on the day. Always 0 for filler days.
    let count: Int

    var id: Date { date }

    var hasExpenses: Bool { count > 0 }
}

/// One pay cycle laid out as whole weeks.
struct CycleCalendar {
    /// Week rows, each exactly 7 cells, ordered by `calendar.firstWeekday`.
    let weeks: [[CalendarDay]]
    /// The largest in-cycle day total — the denominator for dot intensity.
    /// Zero when the cycle has no spending.
    let maxDayTotal: Decimal

    /// Every cell, flattened, in date order.
    var days: [CalendarDay] { weeks.flatMap { $0 } }

    /// The cycle's own days, filler excluded.
    var cycleDays: [CalendarDay] { days.filter(\.inCycle) }
}

/// How heavy a day's spend is relative to the cycle's heaviest day. Rendered as the
/// printed total's *weight* (and tone) — meaning must never rest on color alone
/// (revamp guardrail).
enum DayIntensity {
    case none, light, medium, heavy, heaviest
}

/// Lay `cycle` out as whole weeks and attach each day's spend.
///
/// `expenses` may be the whole store: everything outside the cycle is dropped first,
/// so an expense dated on a filler day never shows up in the grid.
func cycleCalendar(for cycle: PayCycle, expenses: [Expense], calendar: Calendar) -> CycleCalendar {
    let inCycle = expenses.filter { cycle.contains($0.date) }
    let totals = Dictionary(
        uniqueKeysWithValues: expenseDayGroups(inCycle, calendar: calendar)
            .map { ($0.day, (total: $0.total, count: $0.expenses.count)) }
    )

    let first = startOfWeek(containing: cycle.start, calendar: calendar)
    let last = startOfWeek(containing: cycle.lastDay(calendar: calendar), calendar: calendar)
    // `last` is the final row's first day, so the grid ends 6 days later.
    let rowCount = (calendar.dateComponents([.day], from: first, to: last).day ?? 0) / 7 + 1

    let weeks: [[CalendarDay]] = (0..<rowCount).map { row in
        (0..<7).map { column in
            let day = calendar.date(byAdding: .day, value: row * 7 + column, to: first) ?? first
            let owned = cycle.contains(day)
            let spend = owned ? totals[day] : nil
            return CalendarDay(
                date: day,
                inCycle: owned,
                total: spend?.total ?? 0,
                count: spend?.count ?? 0
            )
        }
    }

    return CycleCalendar(
        weeks: weeks,
        maxDayTotal: weeks.flatMap { $0 }.map(\.total).max() ?? 0
    )
}

/// Bucket a day's total against the cycle's heaviest day.
///
/// Ratio thresholds: `> 0.75` heaviest, `> 0.50` heavy, `> 0.25` medium, else light.
/// A day with no spend — or any day when the cycle is empty — is `.none`.
func dayIntensity(total: Decimal, max: Decimal) -> DayIntensity {
    guard total > 0, max > 0 else { return .none }
    let ratio = (total as NSDecimalNumber).doubleValue / (max as NSDecimalNumber).doubleValue
    switch ratio {
    case let r where r > 0.75: return .heaviest
    case let r where r > 0.50: return .heavy
    case let r where r > 0.25: return .medium
    default: return .light
    }
}

/// The day's total, abbreviated to fit a ~48pt calendar cell: `145_000` → `"145k"`.
/// Nil when the day has no spend, so the cell renders nothing.
///
/// Deliberately not a money string: no `Rp`, no decimals, no thousands separator. The
/// separator and decimal mark are locale-dependent and would collide with the app's own
/// `Rp145.000` convention inside a four-glyph budget. The authoritative figures — the day
/// header, every row, and this cell's VoiceOver label — all still use `formattedIDR()`.
/// A millions-scale day stays in thousands (`1_200_000` → `"1200k"`), which still fits.
func abbreviatedDayTotal(_ total: Decimal) -> String? {
    guard total > 0 else { return nil }
    let thousands = (total / 1000).doubleValue.rounded()
    // Floor at 1k: any day with spending must read as spending, never as "0k".
    return "\(max(1, Int(thousands)))k"
}

/// Which day to select when the calendar first appears (or after paging cycles):
/// today when the cycle owns it, else the most recent day that has spending, else
/// the cycle's last day. Nil only for a cycle with no days at all.
func defaultSelectedDay(in calendarGrid: CycleCalendar, today: Date, calendar: Calendar) -> Date? {
    let days = calendarGrid.cycleDays
    guard !days.isEmpty else { return nil }
    let startOfToday = calendar.startOfDay(for: today)
    if days.contains(where: { $0.date == startOfToday }) { return startOfToday }
    if let spent = days.last(where: \.hasExpenses) { return spent.date }
    return days.last?.date
}

/// The first day of the week containing `date`, honouring `calendar.firstWeekday`
/// so a Monday-first locale renders Monday-first.
private func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
    let day = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: day)
    let offset = (weekday - calendar.firstWeekday + 7) % 7
    return calendar.date(byAdding: .day, value: -offset, to: day) ?? day
}
