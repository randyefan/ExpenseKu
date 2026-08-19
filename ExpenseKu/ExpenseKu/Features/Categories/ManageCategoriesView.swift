//
//  ManageCategoriesView.swift
//  ExpenseKu
//
//  CRUD for categories. Add/rename route through the de-dup editor (ADR-0002);
//  delete relies on the .nullify rule so referencing expenses become
//  "Uncategorized" rather than being destroyed (ADR-0001).
//

import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var editor: EditorTarget?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button { editor = EditorTarget(category: category) } label: {
                    HStack(spacing: 12) {
                        CategoryIcon(category: category, size: 36)
                        Text(category.name)
                            .font(.dsBody)
                            .foregroundStyle(Theme.text)
                        Spacer()
                    }
                }
                .listRowBackground(Theme.card)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(category: nil) } label: {
                    Label("Add Category", systemImage: "plus")
                }
                .accentCircleButton()
            }
        }
        .overlay {
            if categories.isEmpty {
                EmptyStateView(title: "No Categories", systemImage: "folder",
                    message: "Add one with the + button.")
            }
        }
        .sheet(item: $editor) { target in
            NavigationStack {
                AppearanceEntityEditor<Category>(
                    title: target.category == nil ? "New Category" : "Edit Category",
                    editing: target.category,
                    makeNew: { Category() }
                )
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(categories[index]) }
        try? context.save()
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let category: Category?
    }
}
