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
            .navigationBarTitleDisplayMode(.inline)
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

