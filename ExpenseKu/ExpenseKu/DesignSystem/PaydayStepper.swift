//
//  PaydayStepper.swift
//  ExpenseKu — DesignSystem
//
//  The − value + control for the monthly start date, with an adjustable action so
//  VoiceOver can change it without hitting the two buttons.
//

import SwiftUI

struct PaydayStepper: View {
    @Binding var payday: Int
    var accessibilityTitle: String = "Monthly Start Date"

    var body: some View {
        HStack(spacing: 0) {
            button(systemImage: "minus", tint: Theme.textSecondary, enabled: payday > Payday.range.lowerBound) {
                payday = max(Payday.range.lowerBound, payday - 1)
            }
            Text("\(payday)")
                .font(.dsBody).fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .frame(minWidth: 40)
            button(systemImage: "plus", tint: Theme.accent, enabled: payday < Payday.range.upperBound) {
                payday = min(Payday.range.upperBound, payday + 1)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(Theme.textSecondary.opacity(0.1), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue("Day \(payday)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: payday = min(Payday.range.upperBound, payday + 1)
            case .decrement: payday = max(Payday.range.lowerBound, payday - 1)
            @unknown default: break
            }
        }
    }

    private func button(systemImage: String, tint: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.dsBody.weight(.semibold))
                .foregroundStyle(enabled ? tint : Theme.textSecondary.opacity(0.4))
                .frame(width: 36, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

#Preview {
    @Previewable @State var payday = 25
    VStack(spacing: Metric.cardGap) {
        PaydayStepper(payday: $payday)
        Text("payday = \(payday)").font(.dsCaption)
    }
    .padding()
    .warmBackground()
}
