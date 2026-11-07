//
//  ExpenseEditorView.swift
//  ExpenseKu
//
//  The core logging loop: add or edit an Expense. The amount is driven by an
//  always-docked calculator keypad (design.md §2, calculator revamp); above it every
//  choice made on most entries is one tap (docs/prd/quick-entry-form.md, flow AF C4):
//  date shortcuts, a Category grid, People chips and an Account menu, then the
//  Envelope and the note. Tapping the note swaps the keypad for the native keyboard.
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
    private let hasPresetDate: Bool

    @State private var expr: ExpressionEvaluator  // keypad-driven amount
    @State private var date: Date
    @State private var note: String
    @State private var category: Category?
    @State private var people: [Person]
    @State private var account: Account?
    @State private var envelopeChoice: EnvelopeChoice

    @State private var whenTap: WhenTap?
    @State private var order = QuickPickOrder()
    @State private var pulledCategory: PersistentIdentifier?
    @State private var joinedPeople: [PersistentIdentifier] = []
    @State private var picker: EditorPicker?
    @State private var showingNewAccount = false

    /// The protected owner entry, auto-selected on a new expense (design: "Me by
    /// default"). Empty until `reconcileMe` has run, but that happens at app launch.
    @Query(filter: #Predicate<Person> { $0.isMe }) private var me: [Person]
    @Query(sort: \CyclePlan.cycleStart) private var plans: [CyclePlan]
    @Query(sort: \Category.name) private var allCategories: [Category]
    @Query(sort: \Person.name) private var allPeople: [Person]
    @Query(sort: \Account.name) private var allAccounts: [Account]
    /// The last 90 days, newest first: what the one-tap orders and the default Account
    /// are read from.
    @Query private var recent: [Expense]
    /// Taken right after the defaults are applied, so they alone do not count as a
    /// change. Also guards the one-shot defaults so re-appearing (e.g. returning from
    /// the People picker after the user unselected "Me") doesn't re-add them.
    @State private var pristine: Draft?

    @FocusState private var notesFocused: Bool
    @State private var scrollPosition = ScrollPosition()
    @State private var formHeight: CGFloat?

    /// `envelope` and `date` preset a new expense from ＋ on an envelope row (frame Q5).
    init(editing: Expense? = nil, envelope: PlanItem? = nil, date: Date? = nil,
         onFinish: (() -> Void)? = nil) {
        self.editing = editing
        self.onFinish = onFinish
        self.hasPresetDate = date != nil
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _date = State(initialValue: editing?.date ?? date ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
        _envelopeChoice = State(initialValue: editing.map(EnvelopeChoice.of)
                                ?? envelope.map { .envelope($0.persistentModelID) } ?? .byCategory)
        let since = QuickPicks.windowStart(now: .now, calendar: .current)
        _recent = Query(filter: #Predicate<Expense> { $0.date >= since },
                        sort: [SortDescriptor(\Expense.date, order: .reverse)])
    }

    private enum EditorPicker: Hashable {
        case categories
        case people
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

    private var categoryTiles: [Category] {
        allCategories.ordered(by: QuickPicks.categoryTiles(ranking: order.categories, pulled: pulledCategory))
    }

    private var peopleRail: [Person] {
        allPeople.ordered(by: QuickPicks.peopleRail(me: me.first?.persistentModelID,
                                                    ranking: order.people, joined: joinedPeople))
    }

    private var everyone: [Person] {
        allPeople.filter(\.isMe) + allPeople.filter { !$0.isMe }
    }

    var body: some View {
        editorBody
            .onAppear(perform: applyDefaultsIfNeeded)
            .confirmsDiscard(when: hasChanges, onDiscard: finish)
    }

    /// Runs once. A new expense starts tagged "Me", on the Account last logged by hand,
    /// with Now lit; the one-tap orders are frozen here so nothing reshuffles while
    /// the form is open.
    private func applyDefaultsIfNeeded() {
        guard pristine == nil else { return }
        order = QuickPickOrder(recent: recent, categories: allCategories, people: allPeople,
                               accounts: allAccounts, now: .now)
        if editing == nil {
            if let me = me.first, !people.contains(where: { $0.persistentModelID == me.persistentModelID }) {
                people.insert(me, at: 0)
            }
            if let id = QuickPickOrder.defaultAccount(latestFirst: recent) {
                account = allAccounts.first { $0.persistentModelID == id }
            }
            if !hasPresetDate {
                whenTap = WhenTap(shortcut: .now, date: date)
            }
        }
        pull(category)
        join(people)
        pristine = draft
    }

    /// A Category outside the grid takes its first tile for the life of the form (§4.2).
    private func pull(_ category: Category?) {
        guard let id = category?.persistentModelID,
              !QuickPicks.categoryTiles(ranking: order.categories, pulled: pulledCategory).contains(id)
        else { return }
        pulledCategory = id
    }

    /// A Person tagged from outside the rail joins it for the life of the form (§4.4).
    private func join(_ people: [Person]) {
        let rail = QuickPicks.peopleRail(me: me.first?.persistentModelID, ranking: order.people, joined: joinedPeople)
        for id in people.map(\.persistentModelID) where !rail.contains(id) && !joinedPeople.contains(id) {
            joinedPeople.append(id)
        }
    }

    // MARK: - Amount, one-tap choices, envelope and note above the sticky keypad dock

    private var editorBody: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                        .padding(.horizontal, Metric.screenPadding)

                    WhenShortcutRow(date: $date, tap: $whenTap)

                    CategoryGrid(categories: categoryTiles, selection: $category) {
                        picker = .categories
                    }

                    PeopleChipRail(rail: peopleRail, everyone: everyone, selection: $people) {
                        picker = .people
                    }

                    AccountMenuRow(accounts: allAccounts.ordered(by: order.accounts, appendingRest: true),
                                   selection: $account) {
                        showingNewAccount = true
                    }

                    EnvelopeNoteCard(envelope: envelopeField, category: category,
                                     note: $note, notesFocused: $notesFocused)
                        .id(notesRowID)
                }
                .padding(.bottom, 16)
                .scrollTargetLayout()
            }
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
            .onChange(of: category) { _, newValue in
                pull(newValue)
            }
            .onChange(of: people) { _, newValue in
                join(newValue)
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
        .navigationDestination(item: $picker) { destination in
            switch destination {
            case .categories: CategoryPicker(selection: $category)
            case .people: PeoplePicker(selection: $people)
            }
        }
        .sheet(isPresented: $showingNewAccount) {
            NavigationStack {
                AppearanceEntityEditor(title: "New Account", makeNew: { Account() }) { created in
                    account = created
                }
            }
            .presentationBackground(Theme.bg)
        }
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
        PaidElsewhere.setAccount(account, on: target)
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
