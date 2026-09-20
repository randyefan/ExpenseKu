//
//  IncomeLineEditorView.swift
//  ExpenseKu
//
//  Adding or editing one income line (frame I1).
//
//  Free-typed: a name, an amount, and whether it has arrived. No Category and no
//  Account, because "Gaji Fulltime", "THR" and a freelance payment share nothing worth
//  modelling (decision 6). It reuses the expense editor's keypad, since an income line
//  is the one other place in the app where a rupiah figure is typed from scratch.
//

import SwiftUI
import SwiftData

struct IncomeLineEditorView: View {
    let plan: CyclePlan
    let editing: IncomeLine?
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var expr: ExpressionEvaluator
    @State private var name: String
    @State private var hasArrived: Bool
    @FocusState private var nameFocused: Bool

    init(plan: CyclePlan, editing: IncomeLine?, onFinish: @escaping () -> Void) {
        self.plan = plan
        self.editing = editing
        self.onFinish = onFinish
        _expr = State(initialValue: ExpressionEvaluator(amount: editing?.amount ?? 0))
        _name = State(initialValue: editing?.name ?? "")
        _hasArrived = State(initialValue: editing?.hasArrived ?? false)
    }

    private var resolvedAmount: Decimal { expr.committedAmount }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && resolvedAmount > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }

                    Section {
                        TextField("Name", text: $name)
                            .font(.dsBody)
                            .focused($nameFocused)
                            .listRowBackground(Theme.card)

                        Toggle(isOn: $hasArrived) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sudah masuk").font(.dsBody)
                                Text("Money has landed. This does not change the Sisa.")
                                    .font(.dsCaption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .tint(Theme.accent)
                        .listRowBackground(Theme.card)
                    }

                    if editing != nil {
                        Section {
                            Button("Delete income line", role: .destructive, action: delete)
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
            .navigationTitle("Income line")
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

    private func save() {
        guard canSave else { return }
        let target: IncomeLine
        if let editing {
            target = editing
        } else {
            target = IncomeLine(plan: plan)
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.amount = resolvedAmount
        target.hasArrived = hasArrived
        target.plan = plan
        try? context.save()
        onFinish()
    }

    private func delete() {
        if let editing {
            context.delete(editing)
            try? context.save()
        }
        onFinish()
    }
}
