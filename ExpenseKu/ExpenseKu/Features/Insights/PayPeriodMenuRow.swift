//
//  PayPeriodMenuRow.swift
//  ExpenseKu
//
//  The row under the period chips while Pay period is on: a Menu of every cycle from
//  the current one back to the oldest expense's (docs/prd/insights-drill-in.md §5).
//  It replaced the Payday stepper; the payday is set in Expenses alone. Toggles in a
//  titled Section rather than a Picker, for PlanSortMenu's reason.
//

import SwiftUI

struct PayPeriodMenuRow: View {
    let cycles: [PayCycle]
    let selected: PayCycle
    let onSelect: (PayCycle) -> Void

    @Environment(\.calendar) private var calendar

    var body: some View {
        Menu {
            Section("Pay period") {
                ForEach(cycles) { cycle in
                    Toggle(isOn: Binding(get: { cycle == selected }, set: { _ in onSelect(cycle) })) {
                        Text(cycle.title(calendar: calendar))
                        Text(cycle.rangeText(calendar: calendar))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Label("Pay period", systemImage: "calendar")
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text(selected.title(calendar: calendar))
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.accentText)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.accentText)
            }
            .cardStyle()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pay period")
        .accessibilityValue(selected.title(calendar: calendar))
    }
}

#Preview {
    let now = Date.now
    let current = PayCycle.containing(now, payday: 25)
    let cycles = [current, current.previous(payday: 25), current.previous(payday: 25).previous(payday: 25)]
    PayPeriodMenuRow(cycles: cycles, selected: current, onSelect: { _ in })
        .padding()
        .appBackground()
}
