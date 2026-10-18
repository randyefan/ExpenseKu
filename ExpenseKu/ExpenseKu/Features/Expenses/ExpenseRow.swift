//
//  ExpenseRow.swift
//  ExpenseKu
//
//  One expense inside a day's ledger card, led by its Account's mark with the category
//  as a badge on it (docs/prd/bank-logos.md §5.5, flow Z): bold category name, a single
//  grey meta line (note · companions), and the bold amount right-aligned with monospaced
//  digits, the Account's name under it. An Unassigned expense leads with its category.
//
//  A plan tag gets a line of its own above the category (envelope-assignment.md §4.11):
//  beside the meta line it took the row's middle and squeezed a long note into a narrow
//  column of wrapped lines.
//
//  Search results set `dateLabel` because they span years and each row has to say
//  when it happened; the cycle list and calendar leave it nil, where the day card's
//  own header already answers that.
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    /// When set, shown under the amount as quiet metadata. Nil in the day-grouped lenses.
    var dateLabel: String? = nil

    @Environment(\.planOrigins) private var planOrigins
    @Environment(\.showsPlanOriginTags) private var showsPlanOriginTags
    @Environment(\.expenseRowAccountsLead) private var accountsLead

    private var categoryName: String { expense.category?.name ?? "Uncategorized" }

    private var peopleNames: String { CompanionNames.phrase(expense.people) }

    private var origin: PlanOrigin? {
        showsPlanOriginTags ? planOrigins.origin(of: expense) : nil
    }

    private var lead: ExpenseRowLead {
        ExpenseRowLead.resolve(hasAccount: expense.account != nil, accountsLead: accountsLead)
    }

    var body: some View {
        HStack(spacing: 14) {
            ExpenseRowMark(expense: expense, lead: lead)

            VStack(alignment: .leading, spacing: 2) {
                if let origin {
                    PlanOriginTag(origin: origin)
                        .padding(.bottom, 2)
                }

                Text(categoryName)
                    .font(.dsBody)
                    .bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                ExpenseMetaLine(note: expense.note, peopleNames: peopleNames)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                MoneyText(expense.amount, font: .dsBody, color: Theme.text)

                if lead.showsAccountName, let account = expense.account {
                    ExpenseAccountLabel(account: account)
                }

                if let dateLabel {
                    Text(dateLabel)
                        .font(.dsCaption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
        }
        .padding(.vertical, 10)
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
    .padding(.horizontal, Metric.cardPadding)
    .cardStyle(padding: 0)
    .padding()
    .appBackground()
}

#Preview("Minimal") {
    ExpenseRow(expense: Expense(amount: 25_000, category: Category(name: "Kopi")))
        .padding(.horizontal, Metric.cardPadding)
        .cardStyle(padding: 0)
        .padding()
        .appBackground()
}

#Preview("Uncategorized (ADR-0001)") {
    ExpenseRow(expense: Expense(amount: 45_000, note: "Lunch"))
        .padding(.horizontal, Metric.cardPadding)
        .cardStyle(padding: 0)
        .padding()
        .appBackground()
}

#Preview("Nama panjang") {
    ExpenseRow(expense: Expense(
        amount: 1_250_000,
        note: "A note long enough that it has to be truncated somewhere",
        category: Category(name: "Entertainment and Subscriptions"),
        people: [Person(name: "Tarisa"), Person(name: "Fadil"), Person(name: "Budi")],
        account: Account(name: "Bank Central Asia")
    ))
    .padding(.horizontal, Metric.cardPadding)
    .cardStyle(padding: 0)
    .padding()
    .appBackground()
}

#Preview("Aksesibilitas XXL") {
    ExpenseRow(expense: Expense(
        amount: 120_000, note: "Dinner", category: Category(name: "Makan"),
        people: [Person(name: "Tarisa")], account: Account(name: "GoPay")
    ))
    .padding(.horizontal, Metric.cardPadding)
    .cardStyle(padding: 0)
    .padding()
    .appBackground()
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Gelap") {
    ExpenseRow(expense: Expense(
        amount: 120_000, note: "Dinner", category: Category(name: "Makan"),
        people: [Person(name: "Tarisa")], account: Account(name: "GoPay")
    ))
    .padding(.horizontal, Metric.cardPadding)
    .cardStyle(padding: 0)
    .padding()
    .appBackground()
    .preferredColorScheme(.dark)
}
