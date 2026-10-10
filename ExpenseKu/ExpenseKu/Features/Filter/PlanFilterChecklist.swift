//
//  PlanFilterChecklist.swift
//  ExpenseKu
//
//  The Plan page of the Filter sheet (docs/prd/expense-filter.md §4.8): the same plan
//  filter the split chips set, as a single choice. All sits in a card of its own, as each
//  dimension's empty value does.
//

import SwiftUI

struct PlanFilterChecklist: View {
    @Binding var planFilter: PlanFilter?
    let onDone: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(PlanFilter.allCases, id: \.self) { half in
                    row(title: half.title, tint: half.tint, isOn: planFilter == half) { planFilter = half }
                }
            }
            Section {
                row(title: "All", tint: nil, isOn: planFilter == nil) { planFilter = nil }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onDone)
            }
        }
        .sensoryFeedback(.selection, trigger: planFilter)
    }

    private func row(title: String, tint: Color?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(tint ?? Theme.textSecondary.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .frame(width: Metric.rowIconSize)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Theme.accent : Theme.textSecondary.opacity(0.5))
            }
        }
        .listRowBackground(Theme.card)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
