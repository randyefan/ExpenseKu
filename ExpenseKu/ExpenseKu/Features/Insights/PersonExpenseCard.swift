//
//  PersonExpenseCard.swift
//  ExpenseKu
//
//  One expense inside a companion's drill-down. Reuses ExpenseRow and adds the date,
//  which the list on the Expenses tab carries in its section header instead.
//

import SwiftUI

struct PersonExpenseCard: View {
    let expense: Expense

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ExpenseRow(expense: expense)
            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, Metric.iconSize + 12)
        }
        .cardStyle()
    }
}
