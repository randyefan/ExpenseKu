//
//  FilterSheet.swift
//  ExpenseKu
//
//  The Filter sheet (docs/prd/expense-filter.md §4.3): one row per dimension showing its
//  choices, each pushing its checklist. It opens at .medium and grows to .large for a
//  checklist. There is no Cancel: every tick already applied, so Done only closes.
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
                        NavigationLink(value: dimension) {
                            LabeledContent(dimension.title) {
                                Text(catalog.summary(of: filter, in: dimension))
                                    .foregroundStyle(filter.choices(in: dimension).isEmpty ? Theme.textSecondary : Theme.accent)
                                    .lineLimit(1)
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
        .onChange(of: path) { _, newPath in
            if !newPath.isEmpty { detent = .large }
        }
    }
}
