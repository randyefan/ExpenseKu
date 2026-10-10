//
//  FilterSheet.swift
//  ExpenseKu
//
//  The Filter sheet (docs/prd/expense-filter.md §4.3): one row per dimension showing its
//  choices, each pushing its checklist. It opens at .medium and grows to .large for a
//  checklist. There is no Cancel: every tick already applied, so Done only closes.
//
//  The sheet grows first and the checklist is pushed once it has: pushed while still
//  growing, the checklist laid out at the .medium height and left a blank band for a
//  moment as the sheet finished.
//
//  A drill-in hides its subject's own dimension (§6.1), which the subject already fixes.
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filter: ExpenseFilter
    let catalog: FilterCatalog
    var hiding: FilterDimension? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var path: [FilterDimension] = []
    @State private var detent: PresentationDetent = .medium

    static let help = "Choices in one row match any of them. Rows combine: an expense shows only if it matches every row."

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(FilterDimension.allCases.filter { $0 != hiding }, id: \.self) { dimension in
                        Button { open(dimension) } label: {
                            LabeledContent(dimension.title) {
                                HStack(spacing: 8) {
                                    Text(catalog.summary(of: filter, in: dimension))
                                        .foregroundStyle(filter.choices(in: dimension).isEmpty ? Theme.textSecondary : Theme.accent)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.right")
                                        .font(.dsCaption.weight(.semibold))
                                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                                }
                            }
                            .font(.dsBody)
                            .foregroundStyle(Theme.text)
                        }
                        .listRowBackground(Theme.card)
                    }
                } footer: {
                    Text(Self.help)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") { filter = ExpenseFilter() }
                        .disabled(filter.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: FilterDimension.self) { dimension in
                FilterChecklist(
                    dimension: dimension,
                    options: catalog.options(for: dimension),
                    filter: $filter,
                    onDone: { dismiss() }
                )
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
    }

    private func open(_ dimension: FilterDimension) {
        guard detent != .large else {
            path.append(dimension)
            return
        }
        detent = .large
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            path.append(dimension)
        }
    }
}
