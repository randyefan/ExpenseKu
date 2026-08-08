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
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingNew = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    selection = category
                } label: {
                    HStack {
                        Text(category.name)
                        Spacer()
                        if isSelected(category) {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            Button {
                showingNew = true
            } label: {
                Label("New Category", systemImage: "plus")
            }
        }
        .navigationTitle("Category")
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                NameEditorView<Category>(title: "New Category", makeNew: { Category() }) { created in
                    selection = created
                }
            }
        }
    }

    private func isSelected(_ category: Category) -> Bool {
        selection?.persistentModelID == category.persistentModelID
    }
}
