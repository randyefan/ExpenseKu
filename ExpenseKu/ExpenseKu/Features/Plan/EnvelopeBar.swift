//
//  EnvelopeBar.swift
//  ExpenseKu
//
//  An envelope's progress: spent against planned, with the remainder called out.
//
//  It reuses ProportionRow's vocabulary — a capsule track with a capsule fill at the
//  same 10pt height — rather than ProportionRow itself. That type clamps its fraction
//  to 1 and serves two Insights charts; an envelope has to show *past* full, which is
//  the one state that matters. Overspend fills the whole track and recolours, and the
//  remainder line flips from "Rp 226.900 left" to "Rp 48.300 over".
//
//  Nothing is ever blocked by going over (PRD §9.3). This reports; it does not stop.
//

import SwiftUI

struct EnvelopeBar: View {
    let progress: EnvelopeProgress

    private let barHeight: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule()
                .fill(Theme.textSecondary.opacity(0.14))
                .frame(height: barHeight)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(fill)
                            .frame(width: width(in: proxy.size.width), height: barHeight)
                    }
                    .frame(height: barHeight)
                }

            HStack(spacing: 8) {
                Text(progress.spent.formattedIDR())
                    .font(.dsCaption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(progress.remainder.formattedIDR()) \(progress.isOver ? "over" : "left")")
                    .font(.dsCaption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(progress.isOver ? Theme.negative : Theme.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spent \(progress.spent.formattedIDR()) of \(progress.planned.formattedIDR())")
        .accessibilityValue(progress.isOver
                            ? "\(progress.remainder.formattedIDR()) over"
                            : "\(progress.remainder.formattedIDR()) left")
    }

    private var fill: Color {
        progress.isOver ? Theme.negative : Theme.accent
    }

    private func width(in available: CGFloat) -> CGFloat {
        let fraction = min(max(progress.fraction, 0), 1)
        return max(barHeight, available * fraction)
    }
}
