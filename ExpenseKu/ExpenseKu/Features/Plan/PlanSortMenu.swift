//
//  PlanSortMenu.swift
//  ExpenseKu
//
//  The trailing control on the plan's PLAN · N ITEMS header (frame M1): a Menu named
//  after the active order. Toggles rather than a Picker: an inline Picker swallows the
//  section title the design draws, and a Toggle still carries the checkmark.
//

import SwiftUI

struct PlanSortMenu: View {
    let sort: PlanSort
    let onChoose: (PlanSort) -> Void

    var body: some View {
        Menu {
            Section("Order the plan by") {
                ForEach(PlanSort.allCases) { option in
                    Toggle(isOn: Binding(get: { sort == option }, set: { _ in onChoose(option) })) {
                        Label(option.title, systemImage: option.systemImage)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(sort.title)
            }
            .font(.dsCaption.weight(.semibold))
            .foregroundStyle(Theme.accentText)
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .accessibilityLabel("Order the plan by")
        .accessibilityValue(sort.title)
    }
}

#Preview {
    PlanSortMenu(sort: .account, onChoose: { _ in })
        .padding()
        .background(Theme.bg)
}
