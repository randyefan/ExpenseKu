//
//  EditorKeypadDock.swift
//  ExpenseKu
//
//  The editor's sticky bottom dock: the calculator keypad plus, when editing an
//  existing expense, a restrained Delete button.
//

import SwiftUI

struct EditorKeypadDock: View {
    @Binding var expr: ExpressionEvaluator
    let canSave: Bool
    let showsDelete: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            CalculatorKeypad(
                canSave: canSave,
                onDigit: { expr.appendDigit($0) },
                onDecimal: { expr.appendDecimal() },
                onOperator: { expr.appendOperator($0) },
                onBackspace: { expr.backspace() },
                onClear: { expr.clear() },
                onSave: onSave,
                onCancel: onCancel
            )

            if showsDelete {
                Button("Delete Expense", role: .destructive, action: onDelete)
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
}
