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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// nil = adding a new expense; non-nil = editing an existing one.
    let editing: Expense?
    /// Called after save/cancel/delete. When nil, the view dismisses itself
    /// (sheet or pushed presentation); the Expenses tab's edit sheet passes a closure
    /// that clears its selection instead.
    let onFinish: (() -> Void)?

    @State private var expr: ExpressionEvaluator  // keypad-driven amount
    @State private var date: Date
    @State private var note: String
    @State private var category: Category?
    @State private var people: [Person]
    @State private var account: Account?
    @State private var envelopeChoice: EnvelopeChoice

    /// The protected owner entry, auto-selected on a new expense (design: "Me by
    /// default"). Empty until `reconcileMe` has run, but that happens at app launch.
    @Query(filter: #Predicate<Person> { $0.isMe }) private var me: [Person]
    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]
    /// Taken right after the "Me" default is applied, so that default alone does not
    /// count as a change. Also guards the one-shot default so re-appearing (e.g.
    /// returning from the People picker after the user unselected "Me") doesn't
    /// re-add it.
    @State private var pristine: Draft?

    @FocusState private var notesFocused: Bool
    @State private var scrollPosition = ScrollPosition()
    @State private var formHeight: CGFloat?

    /// `envelope` and `date` preset a new expense from ＋ on an envelope row (frame Q5).
    init(editing: Expense? = nil, envelope: PlanItem? = nil, date: Date? = nil,
         onFinish: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinish = onFinish
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _date = State(initialValue: editing?.date ?? date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
        _envelopeChoice = State(initialValue: editing.map(EnvelopeChoice.of)
                                ?? envelope.map { .envelope($0.persistentModelID) } ?? .byCategory)
    }

    /// The amount that will be saved.
    private var resolvedAmount: Decimal { expr.committedAmount }

    private var canSave: Bool { resolvedAmount > 0 && category != nil }

    private struct Draft: Equatable {
        var expression: String
        var date: Date
        var note: String
        var category: PersistentIdentifier?
        var account: PersistentIdentifier?
        var people: Set<PersistentIdentifier>
        var envelope: EnvelopeChoice
    }

    private var draft: Draft {
        Draft(
            expression: expr.raw,
            date: date,
            note: note,
            category: category?.persistentModelID,
            account: account?.persistentModelID,
            people: Set(people.map(\.persistentModelID)),
            envelope: envelopeChoice
        )
    }

    /// On a tall iPad pane a bottom-docked keypad sits a hand's width below the rows it
    /// fills, so there the form shrinks to its content and the keypad follows it.
    private var keypadFollowsForm: Bool { horizontalSizeClass == .regular }

    private var hasChanges: Bool { pristine.map { $0 != draft } ?? false }

    private var cycle: PayCycle { PayCycle.containing(date, payday: Payday.current) }

    /// The date's cycle and every later one on offer (§4.10.2). Keeping the draft's
    /// choice in it is what lets a date change keep an assignment that still points
    /// forward, and drop one that would now point back (§4.10.4).
    private var envelopeOptions: EnvelopeOptions {
        EnvelopeOptions(
            offer: EnvelopeOffer(cycle: cycle, plans: plans, payday: Payday.current, calendar: .current,
                                 now: .now, keeping: envelopeChoice),
            expenses: []
        )
    }

    /// Drawn only when an envelope is on offer, and never on an expense a Fixed item
    /// created — that one is already From plan (§4.3).
    private var envelopeField: EnvelopeField? {
        let options = envelopeOptions
        guard editing?.planItem == nil, !options.isEmpty else { return nil }
        return EnvelopeField(
            choice: $envelopeChoice,
            value: options.value(for: envelopeChoice, category: category),
            offer: options.offer
        )
    }

    var body: some View {
        editorBody
            .onAppear(perform: applyDefaultsIfNeeded)
            .confirmsDiscard(when: hasChanges, onDiscard: finish)
    }

    /// On a brand-new expense, pre-select the protected "Me" so logging a solo
    /// expense is one tap. Runs once; the user can still unselect it.
    private func applyDefaultsIfNeeded() {
        guard pristine == nil else { return }
        if editing == nil, let me = me.first,
           !people.contains(where: { $0.persistentModelID == me.persistentModelID }) {
            people.insert(me, at: 0)
        }
        pristine = draft
    }

    // MARK: - Big amount hero + scrolling rows + sticky keypad dock

    private var editorBody: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    ExpenseDetailRows(
                        date: $date,
                        category: $category,
                        account: $account,
                        people: $people,
                        envelope: envelopeField
                    )
                    
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
            .dismissesKeyboardOnOutsideTap()
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom
            } action: { _, height in
                formHeight = height
            }
            .frame(maxHeight: keypadFollowsForm ? formHeight ?? .infinity : .infinity)
            .onChange(of: date) {
                envelopeChoice = envelopeChoice.kept(among: envelopeOptions.envelopes)
            }
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

            if keypadFollowsForm {
                Spacer(minLength: 0)
            }
        }
        .readableColumn()
        .background(Theme.bg)
        .presentationSizing(.page)
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
        if target.planItem == nil {
            let envelopes = envelopeOptions.envelopes
            envelopeChoice.kept(among: envelopes).apply(to: target, envelopes: envelopes)
        }
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
