//
//  CycleCalendarLens.swift
//  ExpenseKu
//
//  The Month lens of the Expenses tab: the cycle drawn as a grid of whole weeks, with
//  the selected day's expenses beneath it. A List rather than a ScrollView so those
//  rows keep swipe-to-delete and the same chrome as the list lens.
//

import SwiftUI

struct CycleCalendarLens: View {
    let calendarGrid: CycleCalendar
    let contents: CycleContents
    let cycle: PayCycle
    let storeIsEmpty: Bool
    let calendar: Calendar
    @Binding var selectedDay: Date?
    let resolvedDay: Date?
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void

    var body: some View {
        List {
            Section {
                CycleCalendarGrid(
                    calendarGrid: calendarGrid,
                    selection: Binding(get: { resolvedDay }, set: { selectedDay = $0 }),
                    calendar: calendar
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: 0, leading: Metric.screenPadding,
                    bottom: Metric.cardGap, trailing: Metric.screenPadding
                ))
            }

            if contents.isEmpty {
                Section {
                    InlineMessageCard(
                        title: storeIsEmpty ? "No expenses yet" : "No expenses this cycle",
                        detail: storeIsEmpty
                            ? "Tap + to log your first expense."
                            : "Nothing logged for \(cycle.rangeText(calendar: calendar))."
                    )
                }
            } else if let day = resolvedDay {
                Section {
                    if let group = contents.group(for: day) {
                        ForEach(group.expenses) { expense in
                            ExpenseListRow(expense: expense) { onSelect(expense) }
                        }
                        .onDelete { onDelete($0, group.expenses) }
                    } else {
                        InlineMessageCard(
                            title: "No expenses \(DayLabel.phrase(day, calendar: calendar))",
                            detail: "Tap + to log one."
                        )
                    }
                } header: {
                    DayGroupHeader(
                        title: DayLabel.title(day, calendar: calendar),
                        total: contents.group(for: day)?.total ?? 0
                    )
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }
}
