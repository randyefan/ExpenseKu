//
//  ExpenseRowMark.swift
//  ExpenseKu
//
//  The leading mark of an expense row (docs/prd/bank-logos.md §5.5, flow Z): the
//  Account's 42pt mark with the category as a solid badge on its corner, or the category
//  icon alone. At 18pt only a solid fill reads, so the badge is the tint itself with an
//  ink glyph, ringed in the card colour to lift it off a white logo.
//
//  The badge hangs past the mark's corner; the row's wider spacing keeps it off the text.
//  Hidden from VoiceOver: the row reads the category and the Account as text.
//

import SwiftUI

private let uncategorizedName = "Uncategorized"

extension EnvironmentValues {
    /// Off on a list whose rows all share one Account (§5.5, decision 29).
    @Entry var expenseRowAccountsLead = true
}

struct ExpenseRowMark: View {
    let expense: Expense
    let lead: ExpenseRowLead

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = Metric.rowMarkSize

    static let logoInset: CGFloat = 0.12

    var body: some View {
        Group {
            if lead == .account, let account = expense.account {
                AccountIcon(account: account, size: size, logoInset: Self.logoInset)
                    .overlay(alignment: .bottomTrailing) {
                        CategoryBadge(category: expense.category, markSize: size)
                    }
            } else if let category = expense.category {
                CategoryIcon(category: category, size: size)
            } else {
                CategoryIcon(name: uncategorizedName, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct CategoryBadge: View {
    let category: Category?
    let markSize: CGFloat

    private var symbol: String {
        category?.resolvedSymbol ?? CategoryIcon.symbol(for: uncategorizedName)
    }

    private var tint: Color {
        Theme.categoryTint(hex: category?.colorHex, seed: category?.name ?? uncategorizedName)
    }

    var body: some View {
        let diameter = markSize * 18 / 42
        let ring = markSize / 42
        Circle()
            .fill(tint)
            .frame(width: diameter, height: diameter)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: diameter * 0.5, weight: .bold))
                    .foregroundStyle(Theme.onTint)
            }
            .padding(ring)
            .background(Theme.card, in: .circle)
            .offset(x: ring * 4, y: ring * 4)
    }
}

#Preview {
    let bca = Account(name: "BCA Gaji")
    bca.brandID = "bca"
    return HStack(spacing: 14) {
        ExpenseRowMark(expense: Expense(amount: 43_000, category: Category(name: "Makan"), account: bca),
                       lead: .account)
        ExpenseRowMark(expense: Expense(amount: 5_000, category: Category(name: "Parkir"),
                                        account: Account(name: "Cash", iconName: "banknote.fill")),
                       lead: .account)
        ExpenseRowMark(expense: Expense(amount: 35_000, category: Category(name: "Makan")), lead: .category)
    }
    .padding()
    .background(Theme.card)
    .appBackground()
}
