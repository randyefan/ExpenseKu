//
//  ContentView.swift
//  ExpenseKu
//
//  Placeholder home screen. The real Expenses list + logging loop arrive in
//  tickets 05/06; this exists only so the app compiles and runs after ticket 03.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    var body: some View {
        NavigationStack {
            List(expenses) { expense in
                LabeledContent(expense.note.isEmpty ? "Expense" : expense.note) {
                    Text(expense.amount, format: .number)
                }
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "creditcard",
                        description: Text("Expense logging arrives in ticket 05.")
                    )
                }
            }
            .navigationTitle("ExpenseKu")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Person.self], inMemory: true)
}
