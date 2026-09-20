//
//  DueDayStepper.swift
//  ExpenseKu
//
//  The − n + capsule for a plan item's due day, with a "None" state either side of the
//  range (frame I8).
//
//  Shaped after PaydayStepper, which sets a day-of-month the same way. Kept separate
//  rather than generalised: this one has to represent *no* due day, which the payday
//  anchor never can — a cycle always starts somewhere.
//

import SwiftUI

struct DueDayStepper: View {
    @Binding var day: Int?

    var body: some View {
        HStack(spacing: 4) {
            stepButton("minus", enabled: day != nil) { step(-1) }

            Text(day.map(String.init) ?? "None")
                .font(.dsBody).bold()
                .monospacedDigit()
                .foregroundStyle(day == nil ? Theme.textSecondary : Theme.text)
                .frame(minWidth: 44)

            stepButton("plus", enabled: day != DueDay.range.upperBound) { step(1) }
        }
        .padding(4)
        .background(Theme.textSecondary.opacity(0.1), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Due day")
        .accessibilityValue(day.map { "Day \($0) of the month" } ?? "None")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(1)
            case .decrement: step(-1)
            default: break
            }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.dsSubhead.weight(.semibold))
                .foregroundStyle(enabled ? Theme.accent : Theme.textSecondary.opacity(0.4))
                .frame(width: 34, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.pressableCard)
        .disabled(!enabled)
        .accessibilityHidden(true)
    }

    /// Stepping below 1 returns to "None" rather than wrapping, so clearing a due day
    /// is reachable from the stepper itself and does not need a separate control.
    private func step(_ delta: Int) {
        switch (day, delta) {
        case (nil, 1): day = DueDay.range.lowerBound
        case (nil, _): break
        case (let current?, _):
            let next = current + delta
            day = next < DueDay.range.lowerBound ? nil : min(next, DueDay.range.upperBound)
        }
    }
}
