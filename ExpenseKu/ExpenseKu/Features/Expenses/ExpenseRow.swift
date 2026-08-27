//
//  ExpenseRow.swift
//  ExpenseKu
//
//  One expense as a "Warm Cards" row: pastel category icon, bold category name,
//  a gray meta line (account + companions), an optional note, and the bold
//  charcoal amount right-aligned with monospaced digits. Styling only — the
//  content and list behaviour are unchanged.
//
//  Search results set `dateLabel` because they span years and each row has to say
//  when it happened; the cycle list and calendar leave it nil, where a day header
//  already answers that, and render exactly as before.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    /// When set, shown under the amount as quiet metadata. Nil in the day-grouped lenses.
    var dateLabel: String? = nil

    private var categoryName: String { expense.category?.name ?? "Uncategorized" }

    private var peopleNames: String { CompanionNames.phrase(expense.people) }

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

            VStack(alignment: .trailing, spacing: 3) {
                MoneyText(expense.amount, font: .dsBody, color: Theme.text)

                if let dateLabel {
                    // The day header's total treatment, so this reads as metadata
                    // rather than as a second number on the row.
                    Text(dateLabel)
                        .font(.dsCaption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Lengkap") {
    ExpenseRow(expense: Expense(
        amount: 120_000,
        note: "Dinner",
        category: Category(name: "Makan"),
        people: [Person(name: "Tarisa"), Person(name: "Fadil")],
        account: Account(name: "GoPay")
    ))
    .cardStyle()
    .padding()
    .warmBackground()
}

#Preview("Minimal") {
    ExpenseRow(expense: Expense(amount: 25_000, category: Category(name: "Kopi")))
        .cardStyle()
        .padding()
        .warmBackground()
}

#Preview("Uncategorized (ADR-0001)") {
    ExpenseRow(expense: Expense(amount: 45_000, note: "Lunch"))
        .cardStyle()
        .padding()
        .warmBackground()
}

#Preview("Nama panjang") {
    ExpenseRow(expense: Expense(
        amount: 1_250_000,
        note: "A note long enough that it has to be truncated somewhere",
        category: Category(name: "Entertainment and Subscriptions"),
        people: [Person(name: "Tarisa"), Person(name: "Fadil"), Person(name: "Budi")],
        account: Account(name: "Bank Central Asia")
    ))
    .cardStyle()
    .padding()
    .warmBackground()
}

#Preview("Aksesibilitas XXL") {
    ExpenseRow(expense: Expense(
        amount: 120_000,
        note: "Dinner",
        category: Category(name: "Makan"),
        people: [Person(name: "Tarisa")],
        account: Account(name: "GoPay")
    ))
    .cardStyle()
    .padding()
    .warmBackground()
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Gelap") {
    ExpenseRow(expense: Expense(
        amount: 120_000,
        note: "Dinner",
        category: Category(name: "Makan"),
        people: [Person(name: "Tarisa")],
        account: Account(name: "GoPay")
    ))
    .cardStyle()
    .padding()
    .warmBackground()
    .preferredColorScheme(.dark)
}
