//
//  PersonDayCard.swift
//  ExpenseKu
//
//  One day of a companion's drill-down: the day's header above a single ledger card
//  holding that day's rows, hairline-separated. The same shape the Expenses tab
//  draws, so the two screens agree about what a day looks like.
//

import SwiftUI

struct PersonDayCard: View {
    let group: ExpenseDayGroup
    let calendar: Calendar
    let onSelect: (Expense) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            DayGroupHeader(
                title: DayLabel.spanningTitle(group.day, calendar: calendar),
                total: group.total
            )
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.expenses.enumerated()), id: \.element.id) { index, expense in
                    if index > 0 {
                        Divider()
                            .overlay(Theme.hairline)
                            .padding(.leading, Metric.rowIconSize + 12)
                    }

                    Button {
                        onSelect(expense)
                    } label: {
                        ExpenseRow(expense: expense)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.pressableRow)
                }
            }
            .padding(.horizontal, Metric.cardPadding)
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
        }
    }
}

#Preview {
    let makan = Category(name: "Makan")
    let group = ExpenseDayGroup(day: .now, expenses: [
        Expense(amount: 45_000, note: "Lunch", category: makan, account: Account(name: "Cash")),
        Expense(amount: 120_000, note: "Dinner", category: makan, account: Account(name: "GoPay")),
    ])
    return ScrollView {
        PersonDayCard(group: group, calendar: .current) { _ in }
            .padding(Metric.screenPadding)
    }
    .appBackground()
    .preferredColorScheme(.dark)
}
