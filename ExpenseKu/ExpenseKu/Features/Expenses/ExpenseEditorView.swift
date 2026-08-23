//
//  ExpenseEditorView.swift
//  ExpenseKu
//
//  The core logging loop: add or edit an Expense. On iOS/iPadOS the amount is
//  driven by an always-docked calculator keypad (design.md §2, calculator revamp):
//  the detail rows scroll above a pinned dock of amount display → notes → keypad →
//  delete. Tapping Notes swaps the keypad for the native keyboard. macOS keeps the
//  plain Form with a hardware-keyboard amount field.
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

    @State private var expr: ExpressionEvaluator  // keypad-driven amount
    @State private var date: Date
    @State private var note: String
    @State private var category: Category?
    @State private var people: [Person]
    @State private var account: Account?

    /// The protected owner entry, auto-selected on a new expense (design: "Me by
    /// default"). Empty until `reconcileMe` has run, but that happens at app launch.
    @Query(filter: #Predicate<Person> { $0.isMe }) private var me: [Person]
    /// Guards the one-shot default so re-appearing (e.g. returning from the People
    /// picker after the user unselected "Me") doesn't re-add it.
    @State private var didApplyDefaults = false

    @FocusState private var notesFocused: Bool
    @State private var scrollPosition = ScrollPosition()

    init(editing: Expense? = nil, onFinish: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinish = onFinish
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
    }

    /// The amount that will be saved.
    private var resolvedAmount: Decimal { expr.committedAmount }

    private var canSave: Bool { resolvedAmount > 0 && category != nil }

    var body: some View {
        editorBody
            .onAppear(perform: applyDefaultsIfNeeded)
    }

    /// On a brand-new expense, pre-select the protected "Me" so logging a solo
    /// expense is one tap. Runs once; the user can still unselect it.
    private func applyDefaultsIfNeeded() {
        guard !didApplyDefaults else { return }
        didApplyDefaults = true
        guard editing == nil, let me = me.first,
              !people.contains(where: { $0.persistentModelID == me.persistentModelID })
        else { return }
        people.insert(me, at: 0)
    }

    // MARK: - Big amount hero + scrolling rows + sticky keypad dock

    private var editorBody: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    ExpenseDetailRows(
                        date: $date, category: $category,
                        account: $account, people: $people
                    )
                }

                Section {
                    TextField("Add a note…", text: $note, axis: .vertical)
                        .font(.dsBody)
                        .focused($notesFocused)
                        .listRowBackground(Theme.card)
                        .id(notesRowID)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            // Tapping anywhere outside a text field dismisses the notes
            // keyboard (List gives drag-dismiss but no tap-outside dismiss).
            .dismissesKeyboardOnOutsideTap()
            .scrollPosition($scrollPosition)
            .onChange(of: notesFocused) { _, focused in
                if focused {
                    withAnimation { scrollPosition.scrollTo(id: notesRowID, anchor: .bottom) }
                }
            }

            if !notesFocused {
                EditorKeypadDock(
                    expr: $expr,
                    canSave: canSave,
                    showsDelete: editing != nil,
                    onSave: save,
                    onCancel: finish,
                    onDelete: deleteExpense
                )
            }
        }
        .background(Theme.bg)
        .navigationTitle(editing == nil ? "Add Expense" : "Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: notesFocused)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
    }

    private var notesRowID: String { "notes" }

    // MARK: - Actions

    private func save() {
        guard canSave else { return }
        let target: Expense
        if let editing {
            target = editing
        } else {
            target = Expense()
            context.insert(target)
        }
        target.amount = resolvedAmount
        target.date = date
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.category = category
        target.people = people
        target.account = account
        try? context.save()
        finish()
    }

    private func deleteExpense() {
        if let editing {
            context.delete(editing)
            try? context.save()
        }
        finish()
    }

    private func finish() {
        if let onFinish { onFinish() } else { dismiss() }
    }
}
