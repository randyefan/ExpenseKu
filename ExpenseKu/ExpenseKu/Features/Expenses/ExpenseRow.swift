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
        let names = people.map(\.name).sorted()
        switch names.count {
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            // Oxford comma: "Anas, Beni, and Me"
            return names.dropLast().joined(separator: ", ") + ", and " + names.last!
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let category = expense.category {
                CategoryIcon(category: category)
            } else {
                CategoryIcon(name: categoryName)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(categoryName)
                    .font(.dsBody)
                    .bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .padding(.bottom, 2)

                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                ExpenseMetaLine(
                    accountName: expense.account?.name,
                    peopleNames: peopleNames
                )
            }

            Spacer(minLength: 8)

            MoneyText(expense.amount, font: .dsBody, color: Theme.text)
        }
        .padding(.vertical, 4)
    }
}
