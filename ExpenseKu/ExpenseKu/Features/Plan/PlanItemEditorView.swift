//
//  PlanItemEditorView.swift
//  ExpenseKu
//
//  Adding or editing one plan item (frames F1, F3, I8).
//
//  One editor for both kinds, with the field set changing under the toggle. An
//  Envelope has no Account, no due day and no Auto, because it never creates an
//  Expense — showing those fields greyed would imply they could be filled in.
//
//  The `Auto` switch stays inert until a due day is set: an Auto item without one
//  never fires (PRD §7.4), so an enabled switch would be a promise the app cannot
//  keep. The hint says which way round it goes.
//

import SwiftUI
import SwiftData

struct PlanItemEditorView: View {
    let plan: CyclePlan
    let editing: PlanItem?
    let plans: [CyclePlan]
    let onFinish: () -> Void
    let onDelete: (PlanItem) -> Void

    @Environment(\.modelContext) private var context

    @State private var expr: ExpressionEvaluator
    @State private var name: String
    @State private var kind: PlanItemKind
    @State private var category: Category?
    @State private var account: Account?
    @State private var people: [Person]
    @State private var envelopeCategories: [Category]
    @State private var dueDay: Int?
    @State private var isAuto: Bool
    @FocusState private var nameFocused: Bool

    init(plan: CyclePlan, editing: PlanItem?, plans: [CyclePlan],
         onFinish: @escaping () -> Void, onDelete: @escaping (PlanItem) -> Void) {
        self.plan = plan
        self.editing = editing
        self.plans = plans
        self.onFinish = onFinish
        self.onDelete = onDelete
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _name = State(initialValue: editing?.name ?? "")
        _kind = State(initialValue: editing?.kind ?? .fixed)
        _category = State(initialValue: editing?.category)
        _account = State(initialValue: editing?.account)
        _people = State(initialValue: editing?.people ?? [])
        _envelopeCategories = State(initialValue: editing?.envelopeCategories ?? [])
        _dueDay = State(initialValue: editing?.dueDay)
        _isAuto = State(initialValue: editing?.isAuto ?? false)
    }

    private var resolvedAmount: Decimal { expr.committedAmount }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return kind == .envelope ? !envelopeCategories.isEmpty : category != nil
    }

    private var historyHint: String? {
        PlanItemHistory.hint(for: name, excluding: plan, in: plans)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(spacing: 2) {
                            AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                            if let historyHint {
                                Text(historyHint)
                                    .font(.dsCaption)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                        kindToggle
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }

                    Section {
                        TextField("Name", text: $name)
                            .font(.dsBody)
                            .focused($nameFocused)
                            .listRowBackground(Theme.card)

                        if kind == .envelope {
                            envelopeCategoriesRow
                        } else {
                            fixedFields
                        }
                    } footer: {
                        if kind == .envelope {
                            Text("An envelope never creates an expense. It has no account, no due day and no Auto — its spent total comes from expenses you have already logged.")
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    if let editing {
                        Section {
                            Button("Delete plan item", role: .destructive) { onDelete(editing) }
                                .font(.dsBody)
                                .listRowBackground(Theme.card)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if !nameFocused {
                    EditorKeypadDock(
                        expr: $expr,
                        canSave: canSave,
                        showsDelete: false,
                        onSave: save,
                        onCancel: onFinish,
                        onDelete: {}
                    )
                }
            }
            .background(Theme.bg)
            .navigationTitle(editing == nil ? "New plan item" : "Plan item")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.2), value: nameFocused)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onFinish).tint(Theme.accentText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).tint(Theme.accentText).disabled(!canSave)
                }
            }
        }
    }

    private var kindToggle: some View {
        SegmentedToggle(
            selection: $kind,
            segments: [
                .init(.fixed, title: "Fixed", systemImage: "checkmark.circle"),
                .init(.envelope, title: "Envelope", systemImage: "tray.fill"),
            ]
        )
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var fixedFields: some View {
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
                Text(people.isEmpty ? "None" : people.map(\.name).sorted().joined(separator: ", "))
                    .foregroundStyle(people.isEmpty ? Theme.textSecondary : Theme.text)
                    .lineLimit(1)
            }
            .font(.dsBody)
        }
        .listRowBackground(Theme.card)

        LabeledContent {
            DueDayStepper(day: $dueDay)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Due day").font(.dsBody)
                Text("Day-of-month, not a date. 29–31 clamp to short months.")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .listRowBackground(Theme.card)

        Toggle(isOn: $isAuto) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto").font(.dsBody)
                Text(dueDay == nil
                     ? "Set a due day first — Auto items only fire on one."
                     : "Writes its own expense on the due day, without confirmation.")
                    .font(.dsCaption)
                    .foregroundStyle(dueDay == nil ? Theme.accentText : Theme.textSecondary)
            }
        }
        .tint(Theme.accent)
        .disabled(dueDay == nil)
        .listRowBackground(Theme.card)
        .onChange(of: dueDay) { _, newValue in
            if newValue == nil { isAuto = false }
        }
    }

    private var envelopeCategoriesRow: some View {
        NavigationLink {
            EnvelopeCategoriesPicker(
                selection: $envelopeCategories,
                claims: EnvelopeSpend.claims(in: plan.items ?? [], excluding: editing),
                envelopeName: name
            )
        } label: {
            LabeledContent("Categories") {
                Text(envelopeCategories.isEmpty
                     ? "Required"
                     : envelopeCategories.map(\.name).sorted().joined(separator: ", "))
                    .foregroundStyle(envelopeCategories.isEmpty ? Theme.accent : Theme.text)
                    .lineLimit(1)
            }
            .font(.dsBody)
        }
        .listRowBackground(Theme.card)
    }

    private func save() {
        guard canSave else { return }
        let target: PlanItem
        if let editing {
            target = editing
        } else {
            target = PlanItem(plan: plan)
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.amount = resolvedAmount
        target.kind = kind
        target.plan = plan

        if kind == .envelope {
            target.envelopeCategories = envelopeCategories
            target.category = nil
            target.account = nil
            target.people = []
            target.dueDay = nil
            target.isAuto = false
        } else {
            target.category = category
            target.account = account
            target.people = people
            target.envelopeCategories = []
            target.dueDay = dueDay
            target.isAuto = dueDay == nil ? false : isAuto
        }
        try? context.save()
        onFinish()
    }
}
