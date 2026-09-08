//
//  ProportionRow.swift
//  ExpenseKu — DesignSystem
//
//  A named amount with a bar showing its share of the largest one: the shape the
//  category, account and companion breakdowns all want.
//
//  Replaces the Swift Charts `BarMark` those screens used. A horizontal bar chart
//  with a trailing value annotation has no way to reserve room for the label, so
//  the biggest bar's figure was being clipped off the card edge. Here the figure
//  lives on the name's line, where its width is the layout's problem rather than
//  the plot's, and the bar gets the full width beneath it.
//

import SwiftUI

struct ProportionRow: View {
    let name: String
    let value: Decimal
    /// Share of the largest row, 0…1.
    let fraction: Double
    let tint: Color
    var symbol: String? = nil
    /// The chart-wide 0→1 growth factor; the bar draws `fraction * growth`.
    var growth: Double = 1

    private var barHeight: CGFloat { 10 }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.dsCaption.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 16)
                }
                Text(name)
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(value.formattedIDR())
                    .font(.dsSubhead)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(1)
            }

            Capsule()
                .fill(Theme.textSecondary.opacity(0.14))
                .frame(height: barHeight)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(tint)
                            .frame(
                                width: max(barHeight, proxy.size.width * clampedFraction * growth),
                                height: barHeight
                            )
                    }
                    .frame(height: barHeight)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(value.formattedIDR())
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }
}

#Preview {
    VStack(spacing: 18) {
        ProportionRow(name: "Makan", value: 245_000, fraction: 1,
                      tint: Theme.categoryTint("Makan"), symbol: "fork.knife")
        ProportionRow(name: "Kopi", value: 105_000, fraction: 0.43,
                      tint: Theme.categoryTint("Kopi"), symbol: "cup.and.saucer.fill")
        ProportionRow(name: "Transport", value: 30_000, fraction: 0.12,
                      tint: Theme.categoryTint("Transport"), symbol: "car.fill")
        ProportionRow(name: "Entertainment and Subscriptions", value: 1_250_000, fraction: 0.9,
                      tint: Theme.categoryTint("Fun"), symbol: "gamecontroller.fill")
    }
    .cardStyle()
    .padding()
    .appBackground()
}
