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
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Spacer(minLength: 0)
                    Text("Rp")
                        .font(.dsTitle).fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("0", value: $amount, format: .number)
                        .font(.dsHero).fontWeight(.bold)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .fixedSize()
                        .foregroundStyle(Theme.text)
                        .focused($amountFocused)
                        .decimalKeyboard()
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .listRowBackground(Theme.card)
            }

            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .font(.dsBody)
                    .listRowBackground(Theme.card)

                NavigationLink {
                    CategoryPicker(selection: $category)
                } label: {
                    LabeledContent("Category") {
                        Text(category?.name ?? "Required")
                            .foregroundStyle(category == nil ? Theme.accent : Theme.text)
                    }
                    .font(.dsBody)
                }
                .listRowBackground(Theme.card)

                NavigationLink {
                    AccountPicker(selection: $account)
                } label: {
                    LabeledContent("Account") {
                        Text(account?.name ?? "None")
                            .foregroundStyle(account == nil ? Theme.textSecondary : Theme.text)
                    }
                    .font(.dsBody)
                }
                .listRowBackground(Theme.card)

                NavigationLink {
                    PeoplePicker(selection: $people)
                } label: {
                    LabeledContent("People") {
                        Text(peopleSummary)
                            .foregroundStyle(people.isEmpty ? Theme.textSecondary : Theme.text)
                            .lineLimit(1)
                    }
                    .font(.dsBody)
                }
                .listRowBackground(Theme.card)
            }

            Section {
                TextField("Add a note…", text: $note, axis: .vertical)
                    .font(.dsBody)
                    .listRowBackground(Theme.card)
            }

            if editing != nil {
                Section {
                    Button("Delete Expense", role: .destructive, action: deleteExpense)
                        .font(.dsBody)
                        .listRowBackground(Theme.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(editing == nil ? "Add Expense" : "Edit Expense")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
