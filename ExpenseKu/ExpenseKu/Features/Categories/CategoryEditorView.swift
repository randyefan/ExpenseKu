//
//  CategoryEditorView.swift
//  ExpenseKu
//
//  The Category editor, which now also chooses the category's Group (frame H4).
//
//  A thin wrapper over the shared appearance editor rather than a fourth argument to
//  it: only Category has this row, and Account must not grow one.
//
//  Group is never chosen when logging an expense — it is inherited from here, and its
//  only reader is a plan's share-of-income table (PRD §5.3).
//

import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    let editing: Category?
    var onCommit: (Category) -> Void = { _ in }

    @State private var group: CategoryGroup?

    init(editing: Category? = nil, onCommit: @escaping (Category) -> Void = { _ in }) {
        self.editing = editing
        self.onCommit = onCommit
        _group = State(initialValue: editing?.group)
    }

    var body: some View {
        AppearanceEntityEditor(
            title: editing == nil ? "New Category" : "Edit Category",
            editing: editing,
            makeNew: { Category() },
            onCommit: { category in
                category.group = group
                onCommit(category)
            },
            extras: { groupRow }
        )
    }

    private var groupRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderText("Group")
            NavigationLink {
                GroupPicker(selection: $group)
            } label: {
                LabeledContent("Group") {
                    Text(group?.name ?? "None")
                        .foregroundStyle(group == nil ? Theme.textSecondary : Theme.text)
                }
                .font(.dsBody)
                .padding(.vertical, 12)
                .padding(.horizontal, Metric.cardPadding)
                .background(Theme.card, in: .rect(cornerRadius: Metric.rowRadius))
            }
            .buttonStyle(.pressableRow)

            Text("Coarser than a category: what the money is for. Only a plan's share-of-income table reads it.")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
