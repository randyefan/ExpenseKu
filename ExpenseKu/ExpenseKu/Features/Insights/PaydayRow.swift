//
//  PaydayRow.swift
//  ExpenseKu
//
//  The payday stepper shown on Insights while the "This pay period" preset is active.
//  Writing through to `Payday.current` keeps it the same anchor the Expenses tab's
//  cycle uses (ADR-0004).
//

import SwiftUI

struct PaydayRow: View {
    @Binding var payday: Int

    var body: some View {
        HStack {
            Label("Payday", systemImage: "calendar")
                .font(.dsBody)
                .foregroundStyle(Theme.text)
            Spacer()
            PaydayStepper(payday: $payday, accessibilityTitle: "Payday")
        }
        .cardStyle()
        .onChange(of: payday) { _, newValue in Payday.current = newValue }
    }
}
