//
//  ContentView.swift
//  ExpenseKu
//
//  The Expenses tab: the logging loop's home surface. Add via the + button,
//  tap a row to edit, swipe to delete. The richer list treatment (grouping,
//  adaptive list+detail) is ticket 06.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var editor: EditorTarget?

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    Button {
                        editor = EditorTarget(expense: expense)
                    } label: {
                        ExpenseRow(expense: expense)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "creditcard",
                        description: Text("Tap + to log your first expense.")
                    )
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editor = EditorTarget(expense: nil)
                    } label: {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editor) { target in
                NavigationStack {
                    ExpenseEditorView(editing: target.expense)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(expenses[index]) }
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let expense: Expense?
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Person.self], inMemory: true)
}
