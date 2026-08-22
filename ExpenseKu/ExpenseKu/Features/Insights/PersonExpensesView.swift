//
//  PersonExpensesView.swift
//  ExpenseKu
//
//  The drill-down behind a People-leaderboard row: "which expenses make up my
//  total with this person." Pushed onto the Insights nav stack, carrying the
//  leaderboard's active Period / Category / Account filters so the numbers match
//  the row you tapped. Display-only; aggregation lives in the pure
//  PeopleLeaderboard layer. Warm Cards styling, behaviour unchanged (full amount
//  credited to each companion, so the total mirrors the row exactly).
//

import SwiftUI
import SwiftData

/// What a leaderboard row hands to the detail screen: the person plus the filters
/// that were active when it was tapped. All members are Hashable, so this is a
/// valid `NavigationStack` path value.
struct PersonExpensesRoute: Hashable {
    let person: Person
    let category: Category?
    let account: Account?
    let range: DateRangeFilter
}

struct PersonExpensesView: View {
    let route: PersonExpensesRoute

    @Query private var expenses: [Expense]

    private var listed: [Expense] {
        PeopleLeaderboard.expenses(
            for: route.person,
            from: expenses,
            category: route.category,
            account: route.account,
            dateRange: route.range.range(payday: Payday.current)
        )
    }

    private var total: Decimal { listed.reduce(0) { $0 + $1.amount } }

    /// "Food · Cash" when narrowed, nil when neither category nor account is set.
    private var filterSummary: String? {
        let parts = [route.category?.name, route.account?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                header

                if let filterSummary {
                    Text("Filtered by \(filterSummary)")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 2)
                }

                if listed.isEmpty {
                    EmptyStateView(
                        title: "No Expenses in Range",
                        systemImage: "person.2.slash",
                        message: emptyMessage
                    )
                    .frame(minHeight: 320)
                } else {
                    ForEach(listed) { expense in
                        expenseCard(expense)
                    }

                    Text("Each shared expense credits \(route.person.name) the full amount.")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .navigationTitle(route.person.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PersonAvatar(name: route.person.name, size: 44)
                Text(route.person.name)
                    .font(.dsTitle).bold()
                    .foregroundStyle(Theme.text)
            }

            MoneyText(total, font: .dsHero, color: Theme.text)

            Text("^[\(listed.count) expense](inflect: true) · \(route.range.label)")
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Expense card (reuses ExpenseRow; adds the date this drill-down needs)

    private func expenseCard(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ExpenseRow(expense: expense)
            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, Metric.iconSize + 12)   // align under ExpenseRow's text column
        }
        .cardStyle()
    }

    private var emptyMessage: String {
        if let filterSummary {
            return "\(route.person.name) has no expenses matching \(filterSummary) in \(route.range.label.lowercased())."
        }
        return "\(route.person.name) has no expenses in \(route.range.label.lowercased())."
    }
}
