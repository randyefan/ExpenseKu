//
//  EnvelopeDetailSection.swift
//  ExpenseKu
//
//  One cycle's part of an envelope's detail, grouped by day as the List lens groups it.
//  Only an earlier cycle is headed, above its first day (envelope-detail.md §4.4); the
//  envelope's own cycle reads exactly like the List lens.
//

import SwiftUI

struct EnvelopeDetailSection: View {
    let section: EnvelopeCycleSection
    let calendar: Calendar
    let onOpen: (Expense) -> Void
    let onDelete: ([Expense]) -> Void

    var body: some View {
        let groups = expenseDayGroups(section.expenses, calendar: calendar)
        ForEach(groups.enumerated(), id: \.element.id) { index, group in
            Section {
                ForEach(group.expenses) { expense in
                    ExpenseListRow(expense: expense) { onOpen(expense) }
                }
                .onDelete { offsets in onDelete(offsets.map { group.expenses[$0] }) }
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    if section.isPaidEarly, index == 0 {
                        SectionHeaderText("Paid early · \(section.cycle.title(calendar: calendar))")
                    }
                    DayGroupHeader(title: DayLabel.title(group.day, calendar: calendar), total: group.total)
                }
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
            }
        }
    }
}
