//
//  CycleLensArea.swift
//  ExpenseKu
//
//  The Expenses tab's content area below the header: whichever lens is selected, or
//  the empty state that stands in for it. Split out of ExpensesView so the lens
//  swap has a single place to cross-fade from, and so the cycle-paging transition
//  can wrap the whole area rather than each lens separately.
//

import SwiftUI

struct CycleLensArea: View {
    let contents: CycleContents
    let cycle: PayCycle
    let calendarGrid: CycleCalendar
    let calendar: Calendar
    let lens: ExpensesView.Lens
    let storeIsEmpty: Bool
    @Binding var selectedDay: Date?
    let resolvedDay: Date?
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void

    var body: some View {
        Group {
            switch lens {
            case .list:
                if contents.isEmpty {
                    CycleEmptyState(
                        storeIsEmpty: storeIsEmpty,
                        cycle: cycle,
                        calendar: calendar
                    )
                    .motionTransition(.opacity)
                } else {
                    CycleListLens(
                        dayGroups: contents.dayGroups,
                        calendar: calendar,
                        revealTrigger: AnyHashable(cycle),
                        onSelect: onSelect,
                        onDelete: onDelete
                    )
                    .motionTransition(.opacity)
                }
            case .calendar:
                CycleCalendarLens(
                    calendarGrid: calendarGrid,
                    contents: contents,
                    cycle: cycle,
                    storeIsEmpty: storeIsEmpty,
                    calendar: calendar,
                    selectedDay: $selectedDay,
                    resolvedDay: resolvedDay,
                    onSelect: onSelect,
                    onDelete: onDelete
                )
                .motionTransition(.opacity)
            }
        }
        .motion(Motion.reveal, value: lens)
    }
}

/// The two ways a cycle can show nothing: the store is empty everywhere, or this
/// cycle in particular is.
struct CycleEmptyState: View {
    let storeIsEmpty: Bool
    let cycle: PayCycle
    let calendar: Calendar

    var body: some View {
        if storeIsEmpty {
            EmptyStateView(
                title: "No expenses yet",
                systemImage: "doc.text",
                message: "Tap + to log your first expense."
            )
        } else {
            EmptyStateView(
                title: "No expenses this cycle",
                systemImage: "calendar",
                message: "Nothing logged for \(cycle.rangeText(calendar: calendar))."
            )
        }
    }
}
