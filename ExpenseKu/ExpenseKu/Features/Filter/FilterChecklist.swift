//
//  FilterChecklist.swift
//  ExpenseKu
//
//  One dimension's checklist, pushed inside the Filter sheet (docs/prd/expense-filter.md
//  §4.3): every entity by name, its empty value in a card of its own, and a button that
//  clears this dimension alone. Each tap cycles a row Off → Only → Hidden (§4.9) and
//  applies at once.
//

import SwiftUI

struct FilterChecklist: View {
    let dimension: FilterDimension
    let options: [FilterOption]
    @Binding var filter: ExpenseFilter
    let onDone: () -> Void

    var body: some View {
        let entities = options.filter { $0.choice != .none }
        let empty = options.filter { $0.choice == .none }

        List {
            if !entities.isEmpty {
                Section {
                    ForEach(entities) { row($0) }
                }
            }
            Section {
                ForEach(empty) { row($0) }
            }
            Section {
                Button("Clear \(dimension.title)") { filter.clear(dimension) }
                    .font(.dsBody.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .disabled(!filter.isActive(dimension))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(dimension.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onDone)
            }
        }
        .sensoryFeedback(.selection, trigger: filter)
    }

    private func row(_ option: FilterOption) -> some View {
        FilterOptionRow(
            option: option,
            dimension: dimension,
            mark: filter.mark(of: option.choice, in: dimension)
        ) {
            filter.cycle(option.choice, in: dimension)
        }
    }
}
