//
//  ExpenseRow.swift
//  ExpenseKu
//
//  One row in the expenses list. A basic layout for ticket 05; the list screen
//  itself is refined in ticket 06.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    private var peopleNames: String {
        guard let people = expense.people, !people.isEmpty else { return "" }
        return people.map(\.name).sorted().joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.category?.name ?? "Uncategorized")
                    .font(.headline)
                Spacer()
                Text(expense.amount.formattedIDR())
                    .font(.headline)
                    .monospacedDigit()
            }
            HStack(spacing: 4) {
                Text(expense.date, format: .dateTime.day().month().year())
                if let account = expense.account {
                    Label(account.name, systemImage: "creditcard")
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                }
                if !peopleNames.isEmpty {
                    Text("· \(peopleNames)").lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !expense.note.isEmpty {
                Text(expense.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
