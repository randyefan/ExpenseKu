//
//  CycleCalendarView.swift
//  ExpenseKu
//
//  The Month lens of the Expenses tab: one pay cycle drawn as a card of whole weeks.
//  Each cell is a date number plus that day's total, abbreviated to thousands so it
//  fits a ~48pt column. The total's *weight* ramps with how heavy the day is relative
//  to the cycle's heaviest — weight, not color, so the read survives color-blindness
//  and grayscale (revamp guardrail). Filler days outside the cycle are greyed and
//  inert. Presentation only: the layout comes from `cycleCalendar(...)`.
//

import SwiftUI

struct CycleCalendarGrid: View {
    let calendarGrid: CycleCalendar
    @Binding var selection: Date?
    var calendar: Calendar = .current

    /// At accessibility text sizes the dot is dropped and the number goes bold
    /// instead — the grid stays 7 columns at every size (a reflowing calendar
    /// isn't a calendar), so the number has to win the space.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 4) {
            weekdayHeader
            ForEach(Array(calendarGrid.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(week) { day in
                        DayCell(
                            day: day,
                            intensity: dayIntensity(total: day.total, max: calendarGrid.maxDayTotal),
                            isSelected: day.date == selection,
                            isToday: calendar.isDateInToday(day.date),
                            compact: dynamicTypeSize.isAccessibilitySize,
                            calendar: calendar
                        ) {
                            selection = day.date
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var weekdayHeader: some View {
        // Rotated to the calendar's own firstWeekday so a Monday-first locale
        // labels the columns Monday-first.
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let ordered = (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.dsCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - One day

private struct DayCell: View {
    let day: CalendarDay
    let intensity: DayIntensity
    let isSelected: Bool
    let isToday: Bool
    /// Accessibility text size: drop the dot, bold the number instead.
    let compact: Bool
    let calendar: Calendar
    let select: () -> Void

    private var dayNumber: String {
        "\(calendar.component(.day, from: day.date))"
    }

    var body: some View {
        Button(action: select) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.dsSubhead)
                    .fontWeight(numberWeight)
                    .monospacedDigit()
                    .foregroundStyle(numberColor)
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected {
                            Circle().fill(Theme.accent)
                        } else if isToday {
                            Circle().stroke(Theme.textSecondary.opacity(0.5), lineWidth: 1.5)
                        }
                    }

                // Reserve the total's row even when empty so dates stay on one baseline.
                Text(totalText ?? "")
                    .font(.jakarta(10, relativeTo: .caption2))
                    .fontWeight(totalWeight)
                    .monospacedDigit()
                    .foregroundStyle(totalColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(height: 12)
            }
            .padding(.vertical, 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!day.inCycle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Appearance

    private var numberColor: Color {
        if isSelected { return Theme.card }          // knocked out of the coral fill
        if !day.inCycle { return Theme.textSecondary.opacity(0.4) }
        return Theme.text
    }

    private var numberWeight: Font.Weight {
        // At accessibility sizes the total is gone, so the date's weight is what's
        // left to carry "this day has spending".
        if isSelected || (compact && day.hasExpenses) { return .bold }
        return day.inCycle ? .medium : .regular
    }

    /// The day's total, abbreviated ("145k"). Dropped at accessibility text sizes —
    /// a 7-across grid has no room for a second line there, and the VoiceOver label
    /// still carries the exact amount.
    private var totalText: String? {
        guard !compact, day.inCycle else { return nil }
        return abbreviatedDayTotal(day.total)
    }

    /// Weight ramps with intensity so the heavy days still pop at a glance without
    /// relying on color (guardrail).
    private var totalWeight: Font.Weight {
        switch intensity {
        case .heaviest: return .bold
        case .heavy: return .semibold
        case .medium: return .medium
        case .light, .none: return .regular
        }
    }

    /// Tone reinforces the same ramp — a second, redundant channel, never the only one.
    private var totalColor: Color {
        switch intensity {
        case .heaviest, .heavy: return Theme.text
        default: return Theme.textSecondary
        }
    }

    private var accessibilityLabel: String {
        let date = day.date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        if !day.inCycle { return "\(date), outside this pay cycle" }
        guard day.hasExpenses else { return "\(date), no expenses" }
        let unit = day.count == 1 ? "expense" : "expenses"
        return "\(date), \(day.total.formattedIDR()), \(day.count) \(unit)"
    }
}
