//
//  ExpenseEditorView.swift
//  ExpenseKu
//
//  The core logging loop: add or edit an Expense. Amount is auto-focused for a
//  fast add on iPhone (design.md §2). Category is required; People are optional.
//  Presented inside a NavigationStack so the pickers can push.
//

import SwiftUI
import SwiftData

struct ExpenseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = adding a new expense; non-nil = editing an existing one.
    let editing: Expense?
    /// Called after save/cancel/delete. When nil, the view dismisses itself
    /// (sheet or pushed presentation); a split-view detail pane passes a closure
    /// that clears its selection instead.
    let onFinish: (() -> Void)?

    @State private var amount: Decimal
    @State private var date: Date
    @State private var note: String
    @State private var category: Category?
    @State private var people: [Person]
    @State private var account: Account?
    @FocusState private var amountFocused: Bool

    init(editing: Expense? = nil, onFinish: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinish = onFinish
        _amount = State(initialValue: editing?.amount ?? 0)
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
    }

    private var canSave: Bool { amount > 0 && category != nil }

    private var peopleSummary: String {
        people.isEmpty ? "None" : people.map(\.name).sorted().joined(separator: ", ")
    }

    var body: some View {
        Form {
            Section {
                TextField("Amount", value: $amount, format: .number)
                    .focused($amountFocused)
                    .decimalKeyboard()
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section {
                NavigationLink {
                    CategoryPicker(selection: $category)
                } label: {
                    LabeledContent("Category") {
                        Text(category?.name ?? "Required")
                            .foregroundStyle(category == nil ? .secondary : .primary)
                    }
                }
                NavigationLink {
                    AccountPicker(selection: $account)
                } label: {
                    LabeledContent("Account") {
                        Text(account?.name ?? "None")
                            .foregroundStyle(account == nil ? .secondary : .primary)
                    }
                }
                NavigationLink {
                    PeoplePicker(selection: $people)
                } label: {
                    LabeledContent("People") {
                        Text(peopleSummary)
                            .foregroundStyle(people.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                    }
                }
            }

            Section {
                TextField("Note", text: $note, axis: .vertical)
            }

            if editing != nil {
                Section {
                    Button("Delete Expense", role: .destructive, action: deleteExpense)
                }
            }
        }
        .navigationTitle(editing == nil ? "New Expense" : "Edit Expense")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { finish() }
            }
        }
        .onAppear {
            if editing == nil { amountFocused = true }
        }
    }

    private func save() {
        let target: Expense
        if let editing {
            target = editing
        } else {
            target = Expense()
            context.insert(target)
        }
        target.amount = amount
        target.date = date
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.category = category
        target.people = people
        target.account = account
        finish()
    }

    private func deleteExpense() {
        if let editing { context.delete(editing) }
        finish()
    }

    private func finish() {
        if let onFinish { onFinish() } else { dismiss() }
    }
}
