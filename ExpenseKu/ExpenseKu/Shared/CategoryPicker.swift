//
//  CategoryPicker.swift
//  ExpenseKu
//
//  Single-select category picker for the expense editor (ticket 05). Pick from
//  existing categories or create one inline through the de-dup editor.
//

import SwiftUI
import SwiftData

struct CategoryPicker: View {
    @Binding var selection: Category?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingNew = false

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button {
                        selection = category
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(category: category, size: 36)
                            Text(category.name)
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            if isSelected(category) {
                                Image(systemName: "checkmark")
                                    .font(.dsBody.weight(.bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)
                }
            }
            Section {
                Button { showingNew = true } label: {
                    PickerAddRow(title: "New Category")
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Category")
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                AppearanceEntityEditor<Category>(title: "New Category", makeNew: { Category() }) { created in
                    selection = created
                }
            }
        }
    }

    private func isSelected(_ category: Category) -> Bool {
        selection?.persistentModelID == category.persistentModelID
    }
}
