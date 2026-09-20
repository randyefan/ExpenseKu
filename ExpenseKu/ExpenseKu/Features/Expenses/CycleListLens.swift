//
//  CycleListLens.swift
//  ExpenseKu
//
//  The default lens of the Expenses tab: the cycle's expenses grouped by day, most
//  recent day first. The Month lens (CycleCalendarLens) reads the same day groups, so
//  the two can never disagree about what a day contains.
//
//  Each day is one ledger card holding its rows, rather than a loose header over a
//  stack of individual cards — a day with a single expense used to cost most of the
//  screen. `.insetGrouped` supplies the card shape and keeps swipe-to-delete, which
//  a hand-built ScrollView of cards would lose.
//

import SwiftUI

struct CycleListLens<Header: View>: View {
    let dayGroups: [ExpenseDayGroup]
    let calendar: Calendar
    /// Re-runs the reveal cascade when the owner pages to another cycle.
    var revealTrigger: AnyHashable = 0
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void
    /// The cycle header and lens toggle. They ride inside the list rather than
    /// being pinned above it: at accessibility text sizes a pinned header plus a
    /// wrapped title overflows the screen and gets clipped at both ends.
    @ViewBuilder let header: Header

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }

            ForEach(dayGroups.enumerated(), id: \.element.id) { index, group in
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
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
                }
                .reveal(index, trigger: revealTrigger)
            }
        }
        .cycleLensList()
    }
}
