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
//  The Plan row edits the screen's own plan filter, the one its split chips set (§4.8), so
//  the sheet and the chips can never disagree.
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filter: ExpenseFilter
    @Binding var planFilter: PlanFilter?
    let catalog: FilterCatalog
    var hiding: FilterDimension? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var path: [FilterSheetPage] = []
    @State private var detent: PresentationDetent = .medium

    static let help = "Choices in one row match any of them. Rows combine: an expense shows only if it matches every row."

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    row("Plan", value: planFilter?.title ?? "All", isOn: planFilter != nil, page: .plan)
                    ForEach(FilterDimension.allCases.filter { $0 != hiding }, id: \.self) { dimension in
                        row(dimension.title,
                            value: catalog.summary(of: filter, in: dimension),
                            isOn: !filter.choices(in: dimension).isEmpty,
                            page: .dimension(dimension))
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
                    Button("Clear All") {
                        filter = ExpenseFilter()
                        planFilter = nil
                    }
                    .disabled(filter.isEmpty && planFilter == nil)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: FilterSheetPage.self) { page in
                switch page {
                case .plan:
                    PlanFilterChecklist(planFilter: $planFilter, onDone: { dismiss() })
                case .dimension(let dimension):
                    FilterChecklist(
                        dimension: dimension,
                        options: catalog.options(for: dimension),
                        filter: $filter,
                        onDone: { dismiss() }
                    )
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
    }

    private func row(_ title: String, value: String, isOn: Bool, page: FilterSheetPage) -> some View {
        Button { open(page) } label: {
            LabeledContent(title) {
                HStack(spacing: 8) {
                    Text(value)
                        .foregroundStyle(isOn ? Theme.accent : Theme.textSecondary)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAddTraits(.isButton)
    }

    private func open(_ page: FilterSheetPage) {
        guard detent != .large else {
            path.append(page)
            return
        }
        detent = .large
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            path.append(page)
        }
    }
}
