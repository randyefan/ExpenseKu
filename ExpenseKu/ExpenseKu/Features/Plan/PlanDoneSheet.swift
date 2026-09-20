//
//  PlanDoneSheet.swift
//  ExpenseKu
//
//  Ticking Done: the compact confirmation that turns a plan item into an Expense
//  (frame E4, decision 8).
//
//  The confirmation is not ceremony. Fixed amounts drift — `Tagihan Handphone Ibu`
//  was planned at Rp 280.000 and billed at Rp 407.500, and 407.500 is not a number
//  anyone plans. An Expense carrying the planned figure instead would quietly poison
//  the cycle total, the category chart and the People leaderboard, and go unnoticed
//  for months.
//
//  So the amount arrives prefilled from the plan and ready to overwrite, and
//  everything else is carried across. The item's name becomes the expense's note,
//  without which the ledger would show several rows reading only "Cicilan".
//

import SwiftUI
import SwiftData

struct PlanDoneSheet: View {
    let item: PlanItem
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var expr: ExpressionEvaluator
    @State private var date: Date

    init(item: PlanItem, today: Date = .now, onFinish: @escaping () -> Void) {
        self.item = item
        self.onFinish = onFinish
        _expr = State(initialValue: ExpressionEvaluator(amount: item.amount))
        _date = State(initialValue: today)
    }

    private var resolvedAmount: Decimal { expr.committedAmount }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(spacing: 4) {
                            Text(item.name.isEmpty ? "Plan item" : item.name)
                                .font(.dsTitle).bold()
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.center)
                            Text("Fixed plan item · planned \(item.amount.formattedIDR())")
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                            AmountHero(displayExpression: expr.displayExpression, amount: resolvedAmount)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
                    }

                    Section {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                            .font(.dsBody)
                            .listRowBackground(Theme.card)
                        carried("Category", item.category?.name ?? "Uncategorized")
                        carried("Account", item.account?.name ?? "None")
                        carried("People", item.people?.isEmpty == false
                                ? (item.people ?? []).map(\.name).sorted().joined(separator: ", ")
                                : "None")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                EditorKeypadDock(
                    expr: $expr,
                    saveLabel: "Log this expense",
                    canSave: resolvedAmount > 0,
                    showsDelete: false,
                    onSave: logExpense,
                    onCancel: onFinish,
                    onDelete: {}
                )
            }
            .background(Theme.bg)
            .navigationTitle("Log this expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onFinish).tint(Theme.accentText)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func carried(_ title: String, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value).foregroundStyle(Theme.textSecondary).lineLimit(1)
        }
        .font(.dsBody)
        .listRowBackground(Theme.card)
    }

    private func logExpense() {
        guard resolvedAmount > 0 else { return }
        let expense = Expense(
            amount: resolvedAmount,
            date: date,
            note: item.name,
            category: item.category,
            people: item.people ?? [],
            account: item.account,
            planItem: item
        )
        context.insert(expense)
        try? context.save()
        onFinish()
    }
}
