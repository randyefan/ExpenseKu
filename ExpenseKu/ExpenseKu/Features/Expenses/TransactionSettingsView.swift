//
//  TransactionSettingsView.swift
//  ExpenseKu
//
//  The "Monthly Start Date" sheet reached from the home calendar button. One
//  setting: the day of the month (1–31) the spending cycle resets, shared with
//  the Insights pay-period view. Warm Cards styling; behaviour unchanged.
//

import SwiftUI

struct TransactionSettingsView: View {
    @Binding var payday: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Text("Monthly Start Date")
                        .font(.dsBody)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    PaydayStepper(payday: $payday)
                }
                .cardStyle()

                Text("Your spending cycle resets on this day each month (1–31).")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metric.screenPadding)

                Spacer(minLength: 0)
            }
            .padding(Metric.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
            .navigationTitle("Transaction Settings")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .onChange(of: payday) { _, newValue in
            Payday.current = newValue
        }
    }
}

/// A compact "− value + " stepper matching the ref: gray minus, coral plus,
/// clamped to Payday.range.
private struct PaydayStepper: View {
    @Binding var payday: Int

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
        .accessibilityLabel("Monthly Start Date")
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
