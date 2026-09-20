//
//  GroupPicker.swift
//  ExpenseKu
//
//  Choosing a Category's group (the destination behind frame H4's row).
//
//  Single-select and clearable: a Category belongs to zero or one group, and "None" is
//  an ordinary answer — an ungrouped category simply falls outside the plan's
//  percentage table. A "New Group" row at the foot means one can be made at the moment
//  it is needed, without a trip to Manage.
//

import SwiftUI
import SwiftData

struct GroupPicker: View {
    @Binding var selection: CategoryGroup?

    @Query(sort: \CategoryGroup.name) private var groups: [CategoryGroup]
    @Environment(\.dismiss) private var dismiss
    @State private var showingNew = false

    var body: some View {
        List {
            Section {
                row(name: "None", symbol: "minus.circle", isSelected: selection == nil) {
                    selection = nil
                    dismiss()
                }
                ForEach(groups) { group in
                    row(name: group.name, symbol: group.resolvedSymbol,
                        colorHex: group.colorHex,
                        isSelected: selection?.persistentModelID == group.persistentModelID) {
                        selection = group
                        dismiss()
                    }
                }
            }

            Section {
                Button { showingNew = true } label: {
                    PickerAddRow(title: "New Group")
                }
                .buttonStyle(.pressableRow)
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Group")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNew) {
            NavigationStack { GroupEditorView(editing: nil) }
        }
    }

    private func row(name: String, symbol: String, colorHex: String? = nil,
                     isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CategoryIcon(name: name, systemImage: symbol, colorHex: colorHex,
                             size: Metric.rowIconSize)
                Text(name)
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.dsBody.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .listRowBackground(Theme.card)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
