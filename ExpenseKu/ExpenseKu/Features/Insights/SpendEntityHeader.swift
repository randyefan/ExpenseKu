//
//  SpendEntityHeader.swift
//  ExpenseKu
//
//  The identity band at the top of a category or account drill-in (Flow K): its icon
//  and name over a wash of its own tint, the total in the window, and its share of
//  that window. PersonSpendHeader's shape, with the entity's icon for the avatar, and
//  the same rule that the tint is identity, never a border or a control.
//

import SwiftUI

struct SpendEntityHeader: View {
    let identity: SpendEntityIdentity
    let total: Decimal
    let count: Int
    let windowLabel: String
    /// 0…1, or nil when there is nothing to take a share of.
    var share: Double?
    var planFilter: PlanFilter?
    var growth: Double = 1

    private var tint: Color { Theme.categoryTint(hex: identity.colorHex, seed: identity.name) }

    private var sharePercent: Int { Int((share ?? 0) * 100 + 0.5) }

    private var shareCaption: String {
        let half = planFilter.map { " \($0.phrase)" } ?? ""
        return "\(sharePercent)% of what you spent\(half) in this window"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                CategoryIcon(symbol: identity.symbol, tint: tint, size: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(identity.name)
                        .font(.dsTitle).bold()
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("\(identity.kind) · ^[\(count) expense](inflect: true) · \(windowLabel)")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            MoneyText(total, font: .dsHero, color: Theme.text, rolls: true)

            if let share {
                VStack(alignment: .leading, spacing: 6) {
                    Capsule()
                        .fill(Theme.textSecondary.opacity(0.14))
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            GeometryReader { proxy in
                                Capsule()
                                    .fill(tint)
                                    .frame(
                                        width: max(8, proxy.size.width * min(max(share, 0), 1) * growth),
                                        height: 8
                                    )
                            }
                            .frame(height: 8)
                        }

                    Text(shareCaption)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Share of spending")
                .accessibilityValue("\(sharePercent) percent")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metric.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .fill(tint.opacity(Theme.tintFillOpacity * 0.5))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .stroke(Theme.hairline, lineWidth: 1)
                }
        }
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        SpendEntityHeader(
            identity: SpendEntityIdentity(name: "Makan", kind: "Category", symbol: "fork.knife", colorHex: nil),
            total: 115_000, count: 2, windowLabel: "July 2026", share: 0.7, planFilter: .outsidePlan
        )
        SpendEntityHeader(
            identity: SpendEntityIdentity(name: "GoPay", kind: "Account", symbol: "wallet.pass.fill", colorHex: nil),
            total: 0, count: 0, windowLabel: "All time"
        )
    }
    .padding()
    .appBackground()
    .preferredColorScheme(.dark)
}
