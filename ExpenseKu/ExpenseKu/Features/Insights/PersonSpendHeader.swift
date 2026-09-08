//
//  PersonSpendHeader.swift
//  ExpenseKu
//
//  The identity band at the top of a companion's drill-down: their avatar and name
//  over a wash of their own colour, the total credited to them in the chosen window,
//  and how much of that window's spending they account for.
//
//  The companion's tint is identity, never action — a wash behind the card and the
//  fill of the share bar, never a border or a control. A tinted border reads as a
//  selected state, and a companion whose colour happens to be amber would then wear
//  the accent. Amber stays the only accent.
//

import SwiftUI

struct PersonSpendHeader: View {
    let name: String
    /// The companion's chosen tint; nil derives one from the name.
    var colorHex: String?
    let total: Decimal
    let count: Int
    let rangeLabel: String
    /// This companion's share of everything spent in the window, 0…1. Nil when
    /// nothing was spent at all, where a share is meaningless rather than zero.
    var share: Double?
    /// The 0→1 growth factor the share bar is drawn at.
    var growth: Double = 1

    private var tint: Color { Theme.categoryTint(hex: colorHex, seed: name) }

    private var sharePercent: Int {
        Int((share ?? 0) * 100 + 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                PersonAvatar(name: name, colorHex: colorHex, size: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.dsTitle).bold()
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("^[\(count) expense](inflect: true) · \(rangeLabel)")
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

                    Text("\(sharePercent)% of what you spent in this window")
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
        PersonSpendHeader(name: "Tarisa", total: 1_250_000, count: 12,
                          rangeLabel: "All time", share: 0.42)
        PersonSpendHeader(name: "Budi", colorHex: "3B82F6", total: 0, count: 0,
                          rangeLabel: "This month", share: nil)
    }
    .padding()
    .appBackground()
    .preferredColorScheme(.dark)
}
