//
//  CycleListLens.swift
//  ExpenseKu
//
//  The default lens of the Expenses tab: the cycle's expenses grouped by day, most
//  recent day first. The Month lens (CycleCalendarLens) reads the same day groups, so
//  the two can never disagree about what a day contains.
//

import SwiftUI

struct CycleListLens: View {
    let dayGroups: [ExpenseDayGroup]
    let calendar: Calendar
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void

    var body: some View {
        List {
            ForEach(dayGroups) { group in
                Section {
                    ForEach(group.expenses) { expense in
                        ExpenseListRow(expense: expense) { onSelect(expense) }
                    }
                    .onDelete { onDelete($0, group.expenses) }
                } header: {
                    DayGroupHeader(
                        title: DayLabel.title(group.day, calendar: calendar),
                        total: group.total
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }
}
