//
//  GroupEditorView.swift
//  ExpenseKu
//
//  Add or rename a group, with its colour and icon (frame H3).
//
//  Almost entirely inherited: CategoryGroup conforms to AppearanceEntity, so the stage,
//  the name field, the colour/icon workbench and — the part that matters — ADR-0002's
//  duplicate-name prompt all come from the shared editor unchanged (PRD §9.6).
//
//  What it adds is a read-only list of the categories in the group. Membership is
//  assigned from the Category side (H4), in one direction only: two editors that can
//  each change the same relationship are two chances for them to disagree.
//

import SwiftUI
import SwiftData

struct GroupEditorView: View {
    let editing: CategoryGroup?

    var body: some View {
        AppearanceEntityEditor(
            title: editing == nil ? "New Group" : "Edit Group",
            editing: editing,
            makeNew: { CategoryGroup() },
            extras: { members }
        )
    }

    @ViewBuilder
    private var members: some View {
        let names = (editing?.categories ?? []).map(\.name).sorted()
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderText("Categories in this group")
            if names.isEmpty {
                Text("None yet. A category joins a group from the category's own editor.")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 6) {
                    ForEach(names.prefix(4), id: \.self) { name in
                        PlanChip(kind: .account, text: name)
                    }
                    if names.count > 4 {
                        Text("+\(names.count - 4)")
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                Text("Change membership from Manage → Categories.")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
