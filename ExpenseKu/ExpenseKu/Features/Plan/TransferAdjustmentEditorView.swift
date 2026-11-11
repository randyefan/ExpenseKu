//
//  TransferAdjustmentEditorView.swift
//  ExpenseKu
//
//  The manual adjustment on one transfer line (frame I2).
//
//  It covers cases like the spreadsheet's `ke Superbank −Rp 700.000`: money already
//  sitting in that account, so transfer less. The arithmetic is shown in full —
//  planned, adjustment, transfer — because a signed number on its own is the kind of
//  thing that gets typed with the wrong sign.
//
//  The adjustment is a number inside one plan. The app never claims to know an
//  account's balance, and could not: money moves without passing through it.
//

import SwiftUI
import SwiftData

struct TransferAdjustmentEditorView: View {
    let plan: CyclePlan
    let row: TransferRow
    let account: Account?
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var expr: ExpressionEvaluator
    @State private var isNegative: Bool
    private let pristineAdjustment: Decimal

    init(plan: CyclePlan, row: TransferRow, account: Account?, onFinish: @escaping () -> Void) {
        self.plan = plan
        self.row = row
        self.account = account
        self.onFinish = onFinish
        _expr = State(initialValue: ExpressionEvaluator(amount: abs(row.adjustment)))
        _isNegative = State(initialValue: row.adjustment < 0)
        pristineAdjustment = row.adjustment
    }

    private var adjustment: Decimal {
        isNegative ? -expr.committedAmount : expr.committedAmount
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(spacing: 6) {
                            SectionHeaderText(.adjustment)
                            AmountHero(displayExpression: expr.displayExpression,
                                       amount: expr.committedAmount)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }

                    Section {
                        Picker(AppLocalization.string(.direction), selection: $isNegative) {
                            Text(appLocalized: .transferLess).tag(true)
                            Text(appLocalized: .transferMore).tag(false)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Theme.card)
                    }

                    Section {
                        figureRow(AppLocalization.string(.plannedForThisAccount), row.planned, color: Theme.text)
                        figureRow(AppLocalization.string(.adjustment), adjustment,
                                  color: adjustment < 0 ? Theme.negative : Theme.text)
                        figureRow(AppLocalization.string(.transfer), row.planned + adjustment, color: Theme.accentText)
                    } footer: {
                        Text(appLocalized: .useThisWhenMoneyIsAlreadySittingInTheAccountOr)
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                EditorKeypadDock(
                    expr: $expr,
                    saveLabel: AppLocalization.string(.saveAdjustment),
                    canSave: true,
                    showsDelete: false,
                    onSave: save,
                    onCancel: onFinish,
                    onDelete: {}
                )
            }
            .background(Theme.bg)
            .navigationTitle(AppLocalization.string(.transferDestination(row.accountName)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string(.cancel), action: onFinish).tint(Theme.accentText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.string(.save), action: save).tint(Theme.accentText)
                }
            }
        }
        .confirmsDiscard(when: adjustment != pristineAdjustment, onDiscard: onFinish)
    }

    private func figureRow(_ title: String, _ amount: Decimal, color: Color) -> some View {
        LabeledContent(title) {
            MoneyText(amount, font: .dsBody, color: color)
        }
        .font(.dsBody)
        .listRowBackground(Theme.card)
    }

    /// The line is created here if it does not exist: a TransferLine holds only the
    /// facts the owner sets, so until they set one there is nothing to store.
    private func save() {
        let line = existingLine() ?? {
            let new = TransferLine(account: account, plan: plan)
            context.insert(new)
            return new
        }()
        line.adjustment = adjustment
        line.plan = plan
        line.account = account
        try? context.save()
        onFinish()
    }

    private func existingLine() -> TransferLine? {
        (plan.transferLines ?? []).first {
            $0.account?.persistentModelID == account?.persistentModelID
        }
    }
}
