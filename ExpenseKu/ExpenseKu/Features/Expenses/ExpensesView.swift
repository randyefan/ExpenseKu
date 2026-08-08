//
//  ExpensesView.swift
//  ExpenseKu
//
//  The Expenses tab and the app's home surface. Reverse-chronological, grouped
//  by month. Uses NavigationSplitView so it adapts per device (design.md §1):
//  list + detail-pane editing on iPad/Mac, and a collapsed push on iPhone. Add
//  is always a sheet for the fast logging flow (design.md §2).
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var selection: Expense?
    @State private var showingNew = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(monthGroups) { group in
                    Section(group.title) {
                        ForEach(group.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .tag(expense)
                        }
                        .onDelete { delete($0, in: group) }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
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
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    ExpenseEditorView()
                }
            }
        } detail: {
            if let selection {
                ExpenseEditorView(editing: selection, onFinish: { self.selection = nil })
                    .id(selection.persistentModelID)
            } else {
                ContentUnavailableView(
                    "No Expense Selected",
                    systemImage: "sidebar.right",
                    description: Text("Select an expense to view or edit it.")
                )
            }
        }
    }

    // MARK: - Month grouping

    private struct MonthGroup: Identifiable {
        let id: Date          // start of month
        let title: String
        let expenses: [Expense]
    }

    private var monthGroups: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }
        return grouped.keys.sorted(by: >).map { monthStart in
            MonthGroup(
                id: monthStart,
                title: monthStart.formatted(.dateTime.month(.wide).year()),
                expenses: (grouped[monthStart] ?? []).sorted { $0.date > $1.date }
            )
        }
    }

    private func delete(_ offsets: IndexSet, in group: MonthGroup) {
        for index in offsets {
            let expense = group.expenses[index]
            if expense == selection { selection = nil }
            context.delete(expense)
        }
    }
}
