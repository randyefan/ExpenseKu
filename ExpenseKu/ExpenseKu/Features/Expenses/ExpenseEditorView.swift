//
//  ExpenseEditorView.swift
//  ExpenseKu
//
//  The core logging loop: add or edit an Expense. The amount is driven by an
//  always-docked calculator keypad (design.md §2, calculator revamp); above it every
//  choice made on most entries is one tap (docs/prd/quick-entry-form.md, flow AF C4):
//  date shortcuts, a Category grid, People chips and an Account menu, then the
//  Envelope and the note. Tapping the note swaps the keypad for the native keyboard.
//  Read receipt fills what is still empty from a receipt, and an inbox run opens the form
//  on a shared receipt (docs/prd/receipt-reading.md §4.3–§4.7); a card above the amount
//  says whether Gemma or OCR read it (docs/prd/reading-source.md §4.2).
//

import PhotosUI
import SwiftUI
import SwiftData

struct ExpenseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ReceiptModelStore.self) private var receiptModel
    @Environment(ReceiptReadAhead.self) private var receiptReadAhead

    /// nil = adding a new expense; non-nil = editing an existing one.
    let editing: Expense?
    /// Called after save/cancel/delete. When nil, the view dismisses itself
    /// (sheet or pushed presentation); the Expenses tab's edit sheet passes a closure
    /// that clears its selection instead.
    let onFinish: (() -> Void)?
    private let hasPresetDate: Bool
    private let receiptRun: ReceiptRun?
    private let onRunEnd: ((ReceiptRun.Outcome) -> Void)?

    @State private var expr: ExpressionEvaluator  // keypad-driven amount
    @State private var date: Date
    @State private var note: String
    @State private var noteIsUntouched = true
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

    @State private var receiptImage: Data?
    @State private var receiptSource: ReceiptReadingSource?
    @State private var viewingReceipt = false
    @State private var readingTask: Task<Void, Never>?
    @State private var lookAlike: ReceiptLookAlike?
    @State private var showingPhotos = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingRunCancel = false

    /// `envelope` and `date` preset a new expense from ＋ on an envelope row (frame Q5).
    init(editing: Expense? = nil, envelope: PlanItem? = nil, date: Date? = nil,
         onFinish: (() -> Void)? = nil) {
        self.init(editing: editing, envelope: envelope, date: date, receiptRun: nil, onFinish: onFinish, onRunEnd: nil)
    }

    /// Opens on the run's receipt, reads it, and reports how the form ended (§4.5).
    init(receiptRun: ReceiptRun, onRunEnd: @escaping (ReceiptRun.Outcome) -> Void) {
        self.init(editing: nil, envelope: nil, date: nil, receiptRun: receiptRun, onFinish: nil, onRunEnd: onRunEnd)
    }

    private init(editing: Expense?, envelope: PlanItem?, date: Date?, receiptRun: ReceiptRun?,
                 onFinish: (() -> Void)?, onRunEnd: ((ReceiptRun.Outcome) -> Void)?) {
        self.editing = editing
        self.onFinish = onFinish
        self.hasPresetDate = date != nil
        self.receiptRun = receiptRun
        self.onRunEnd = onRunEnd
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _date = State(initialValue: editing?.date ?? date ?? receiptRun?.item.addedAt ?? .now)
        _note = State(initialValue: editing?.note ?? "")
        _category = State(initialValue: editing?.category)
        _people = State(initialValue: editing?.people ?? [])
        _account = State(initialValue: editing?.account)
        _receiptSource = State(initialValue: editing?.isReceiptToCheck == true ? editing?.receiptSource : nil)
        _envelopeChoice = State(initialValue: editing.map(EnvelopeChoice.of)
                                ?? envelope.map { .envelope($0.persistentModelID) } ?? .byCategory)
        let since = QuickPicks.windowStart(now: .now, calendar: .current)
        _recent = Query(filter: #Predicate<Expense> { $0.date >= since },
                        sort: [SortDescriptor(\Expense.date, order: .reverse)])
    }

    private enum EditorPicker: Hashable {
        case categories
        case people
        case receiptReading
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
            .confirmsDiscard(when: hasChanges && receiptRun == nil, onDiscard: finish)
            .interactiveDismissDisabled(receiptRun != nil)
            .overlay {
                if readingTask != nil {
                    ReadingReceiptOverlay(onCancel: cancelReading)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: readingTask == nil)
            .task { openRunReceipt() }
            .photosPicker(isPresented: $showingPhotos, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                photoItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) { read(data) }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                DocumentCameraView(onScan: { data in
                    showingCamera = false
                    read(data)
                }, onCancel: { showingCamera = false })
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $viewingReceipt) {
                if let viewableReceipt { ReceiptImageViewer(data: viewableReceipt) }
            }
            .alert(AppLocalization.string(.looksAlreadyLogged), isPresented: lookAlikeShown, presenting: lookAlike) { match in
                Button(receiptRun == nil ? AppLocalization.string(.donTFill) : AppLocalization.string(.discardReceipt), role: .destructive) {
                    lookAlike = nil
                    if receiptRun != nil { endRun(.discarded) }
                }
                Button(receiptRun == nil ? AppLocalization.string(.fillAnyway) : AppLocalization.string(.logAnyway), role: .cancel) {
                    lookAlike = nil
                    fill(match.reading, source: match.source, image: match.image)
                }
            } message: { match in
                Text(match.description)
            }
            .confirmationDialog(receiptRun?.subtitle ?? "", isPresented: $showingRunCancel, titleVisibility: .visible) {
                Button(AppLocalization.string(.discardReceipt), role: .destructive) { endRun(.discarded) }
                Button(AppLocalization.string(.later)) { endRun(.later) }
                Button(AppLocalization.string(.keepEditing), role: .cancel) {}
            } message: {
                Text(appLocalized: .discardThisReceiptOrKeepItInTheInboxForLater)
            }
    }

    private var lookAlikeShown: Binding<Bool> {
        Binding(get: { lookAlike != nil }, set: { if !$0 { lookAlike = nil } })
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
            if !hasPresetDate && receiptRun == nil {
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
                    if let receiptSource, readingTask == nil {
                        ReceiptSourceCard(source: receiptSource, modelIsReady: receiptModel.isModelReady) {
                            picker = .receiptReading
                        }
                        .padding(.horizontal, Metric.screenPadding)
                    }

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
            .onChange(of: note) { noteIsUntouched = false }
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
                    onCancel: cancel,
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
        .navigationTitle(editing == nil ? AppLocalization.string(.addExpense) : AppLocalization.string(.editExpense))
        .navigationSubtitle(receiptRun?.subtitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: notesFocused)
        .navigationDestination(item: $picker) { destination in
            switch destination {
            case .categories: CategoryPicker(selection: $category)
            case .people: PeoplePicker(selection: $people)
            case .receiptReading: ReceiptReadingView()
            }
        }
        .sheet(isPresented: $showingNewAccount) {
            NavigationStack {
                AppearanceEntityEditor(title: AppLocalization.string(.newAccount), makeNew: { Account() }) { created in
                    account = created
                }
            }
            .presentationBackground(Theme.bg)
        }
        .toolbar {
            if viewableReceipt != nil, readingTask == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(AppLocalization.string(.viewReceipt), systemImage: "doc.text.image") { viewingReceipt = true }
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            ToolbarItem(placement: .primaryAction) {
                ReadReceiptMenu(
                    onPhotos: { showingPhotos = true },
                    onCamera: { showingCamera = true },
                    onPaste: pasteReceipt
                )
                .disabled(readingTask != nil)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppLocalization.string(.done)) { notesFocused = false }
            }
        }
    }

    private var notesRowID: String { "notes" }

    private var viewableReceipt: Data? {
        ViewableReceipt.image(filledFrom: receiptImage, saved: editing?.receiptImage,
                              savedIsToCheck: editing?.isReceiptToCheck == true)
    }

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
        if let receiptImage {
            target.needsReview = true
            target.receiptImage = receiptImage
            target.receiptSource = receiptSource
        } else if target.isReceiptToCheck {
            target.markReceiptChecked()
        }
        try? context.save()
        if receiptRun != nil { endRun(.saved) } else { finish() }
    }

    private func cancel() {
        if receiptRun != nil { showingRunCancel = true } else { finish() }
    }

    private func endRun(_ outcome: ReceiptRun.Outcome) {
        onRunEnd?(outcome)
        dismiss()
    }

    // MARK: - Reading a receipt (§4.3–§4.6)

    private func openRunReceipt() {
        guard let receiptRun, receiptImage == nil, readingTask == nil,
              let data = try? Data(contentsOf: receiptRun.item.url) else { return }
        let categories = allCategories.map(\.name)
        readingTask = Task {
            var stored = await receiptReadAhead.reading(for: receiptRun.item, categories: categories, models: receiptModel)
            while stored == nil, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(300))
                stored = await receiptReadAhead.reading(for: receiptRun.item, categories: categories, models: receiptModel)
            }
            guard let stored, !Task.isCancelled else { return }
            readingTask = nil
            apply(stored, from: data)
        }
    }

    private func pasteReceipt() {
        guard let data = UIPasteboard.general.image?.pngData() else { return }
        read(data)
    }

    private func read(_ data: Data) {
        readingTask?.cancel()
        let categories = allCategories.map(\.name)
        readingTask = Task {
            let stored = await receiptReadAhead.read(data, categories: categories, models: receiptModel)
            guard !Task.isCancelled else { return }
            readingTask = nil
            apply(stored, from: data)
        }
    }

    private func apply(_ stored: StoredReceiptReading, from data: Data) {
        let image = ReceiptImageData.stored(from: data)
        if let match = lookAlikeExpense(for: stored.reading) {
            lookAlike = ReceiptLookAlike(reading: stored.reading, source: stored.shownSource, image: image, expense: match)
        } else {
            fill(stored.reading, source: stored.shownSource, image: image)
        }
    }

    private func cancelReading() {
        readingTask?.cancel()
        readingTask = nil
    }

    private func lookAlikeExpense(for reading: ReceiptReading) -> Expense? {
        guard let day = reading.date?.date(keepingClockOf: .now, calendar: .current) else { return nil }
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return nil }
        let editingID = editing?.persistentModelID
        let sameDay = (try? context.fetch(FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date < end }))) ?? []
        let logged = sameDay
            .filter { $0.persistentModelID != editingID }
            .map { ReceiptDuplicate.Logged(id: $0.persistentModelID, amount: $0.amount, date: $0.date) }
        let id = ReceiptDuplicate.match(reading, in: logged, calendar: .current)
        return sameDay.first { $0.persistentModelID == id }
    }

    private func fill(_ reading: ReceiptReading, source: ReceiptReadingSource?, image: Data) {
        let result = ReceiptFill<PersistentIdentifier>(
            reading: reading,
            form: .init(
                amountIsEmpty: resolvedAmount == 0,
                dateIsUntouched: !hasPresetDate && date == pristine?.date && editing == nil,
                accountIsDefault: account?.persistentModelID == pristine?.account,
                note: note,
                noteIsUntouched: noteIsUntouched,
                hasCategory: category != nil,
                people: people.map(\.persistentModelID),
                clock: date
            ),
            accounts: allAccounts.map { candidate in
                let id = candidate.persistentModelID
                return .init(id: id, brandID: candidate.brandID,
                             uses: recent.count { $0.account?.persistentModelID == id })
            },
            people: allPeople.map { .init(id: $0.persistentModelID, name: $0.name) },
            categories: allCategories.map { .init(id: $0.persistentModelID, name: $0.name) },
            calendar: .current
        )
        guard result.fillsAnything else { return }
        if let expression = result.expression { expr = ExpressionEvaluator(expression) }
        if let filled = result.date {
            date = filled
            whenTap = nil
        }
        if case .set(let id) = result.account {
            account = id.flatMap { id in allAccounts.first { $0.persistentModelID == id } }
        }
        if let filled = result.note { note = filled }
        if let id = result.addedPerson, let person = allPeople.first(where: { $0.persistentModelID == id }) {
            people.append(person)
        }
        if let id = result.category { category = allCategories.first { $0.persistentModelID == id } }
        receiptImage = image
        receiptSource = source
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
