//
//  ExpenseRow.swift
//  ExpenseKu
//
//  One expense as a "Warm Cards" row: pastel category icon, bold category name,
//  a gray meta line (account + companions), an optional note, and the bold
//  charcoal amount right-aligned with monospaced digits. Styling only — the
//  content and list behaviour are unchanged.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    private var categoryName: String { expense.category?.name ?? "Uncategorized" }

    private var peopleNames: String {
        guard let people = expense.people, !people.isEmpty else { return "" }
        return people.map(\.name).sorted().joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(name: categoryName)

            VStack(alignment: .leading, spacing: 3) {
                Text(categoryName)
                    .font(.dsBody)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                metaLine
            }

            Spacer(minLength: 8)

            MoneyText(expense.amount, font: .dsBody, color: Theme.text)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var metaLine: some View {
        HStack(spacing: 4) {
            if let account = expense.account {
                HStack(spacing: 3) {
                    Image(systemName: "creditcard")
                        .fontWeight(.bold)
                    Text(account.name)
                        .fontWeight(.bold)
                }
                .lineLimit(1)
            }
            if !peopleNames.isEmpty {
                Text(expense.account == nil ? peopleNames : "⏤  \(peopleNames)")
                    .lineLimit(1)
            }
        }
        .font(.dsCaption)
        .foregroundStyle(Theme.textSecondary)
    }
}
