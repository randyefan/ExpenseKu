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

    @State private var amount: Decimal            // macOS amount field binding
    @State private var expr: ExpressionEvaluator  // iOS keypad-driven amount
    @State private var date: Date
    @State private var note: String
    @State private var category: Category?
    @State private var people: [Person]
    @State private var account: Account?

    /// The protected owner entry, auto-selected on a new expense (design: "Me by
    /// default"). Empty until `ensureMe` has run, but that happens at app launch.
    @Query(filter: #Predicate<Person> { $0.isMe }) private var me: [Person]
    /// Guards the one-shot default so re-appearing (e.g. returning from the People
    /// picker after the user unselected "Me") doesn't re-add it.
    @State private var didApplyDefaults = false

    @FocusState private var notesFocused: Bool

    init(editing: Expense? = nil, onFinish: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinish = onFinish
        let startAmount = editing?.amount ?? 0
        _amount = State(initialValue: startAmount)
        _expr = State(initialValue: ExpressionEvaluator(amount: startAmount))
        _date = State(initialValue: editing?.date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
    }

    /// The amount that will be saved, resolved per platform.
    private var resolvedAmount: Decimal {
        #if os(iOS)
        expr.committedAmount
        #else
        amount
        #endif
    }

    private var canSave: Bool { resolvedAmount > 0 && category != nil }

    private var peopleSummary: String {
        people.isEmpty ? "None" : people.map(\.name).sorted().joined(separator: ", ")
    }

    var body: some View {
        Group {
            #if os(iOS)
            iosBody
            #else
            macBody
            #endif
        }
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

    // MARK: - Shared detail rows (Date / Category / Account / People)

    @ViewBuilder private var detailRows: some View {
        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
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

    // MARK: - iOS: big amount hero + scrolling rows + sticky keypad dock

    #if os(iOS)
    private var iosBody: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        amountHero
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    }

                    Section { detailRows }

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
                .onChange(of: notesFocused) { _, focused in
                    if focused {
                        withAnimation { proxy.scrollTo(notesRowID, anchor: .bottom) }
                    }
                }
            }

            if !notesFocused {
                dock
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

    /// Sticky bottom dock: keypad plus (when editing) a restrained Delete button.
    private var dock: some View {
        VStack(spacing: 12) {
            CalculatorKeypad(
                canSave: canSave,
                onDigit: { expr.appendDigit($0) },
                onDecimal: { expr.appendDecimal() },
                onOperator: { expr.appendOperator($0) },
                onBackspace: { expr.backspace() },
                onClear: { expr.clear() },
                onSave: save,
                onCancel: finish
            )

            if editing != nil {
                Button("Delete Expense", role: .destructive, action: deleteExpense)
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, Metric.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.bg)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// Big, page-top amount: the calculator working line above the `Rp` result.
    private var amountHero: some View {
        VStack(spacing: 4) {
            if !expr.displayExpression.isEmpty {
                Text(expr.displayExpression)
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Rp")
                    .font(.dsTitle).fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                Text(resolvedAmount.formatted(.number.precision(.fractionLength(0))))
                    .font(.jakarta(48, relativeTo: .largeTitle)).fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(resolvedAmount > 0 ? Theme.text : Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    #endif

    // MARK: - macOS: plain Form

    #if os(macOS)
    private var macBody: some View {
        Form {
            Section {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Spacer(minLength: 0)
                    Text("Rp")
                        .font(.dsTitle).fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                    AmountField(amount: $amount, autoFocus: editing == nil)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .listRowBackground(Theme.card)
            }

            Section { detailRows }

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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { finish() }
            }
        }
    }
    #endif

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
