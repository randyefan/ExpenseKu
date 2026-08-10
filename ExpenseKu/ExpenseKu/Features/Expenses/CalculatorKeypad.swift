//
//  CalculatorKeypad.swift
//  ExpenseKu
//
//  The always-docked calculator keypad for the expense editor (iOS/iPadOS only).
//  Layout mirrors the reference: an operator column on the left, a 3×4 digit
//  block, and a right column where ⌫ spans the top two rows and ✓ the bottom two.
//  The view is "dumb" — it reports presses through closures; the editor owns the
//  `ExpressionEvaluator` and decides what each key means.
//

#if os(iOS)
import SwiftUI
import UIKit

struct CalculatorKeypad: View {
    /// Enables the ✓ (save) key. When false it's dimmed and inert.
    var canSave: Bool

    var onDigit: (Character) -> Void
    var onDecimal: () -> Void
    var onOperator: (CalcOperator) -> Void
    var onBackspace: () -> Void
    var onClear: () -> Void
    var onSave: () -> Void
    var onCancel: () -> Void

    private let spacing: CGFloat = 8
    private let rowHeight: CGFloat = 52
    /// Height of a key that spans two rows (⌫ and ✓).
    private var tallHeight: CGFloat { rowHeight * 2 + spacing }
    private var totalHeight: CGFloat { rowHeight * 4 + spacing * 3 }

    var body: some View {
        GeometryReader { geo in
            let cell = (geo.size.width - spacing * 4) / 5

            HStack(alignment: .top, spacing: spacing) {
                // Operator column.
                VStack(spacing: spacing) {
                    ForEach(CalcOperator.orderedForKeypad, id: \.self) { op in
                        key(width: cell, height: rowHeight) {
                            onOperator(op)
                        } label: {
                            glyph(String(op.rawValue))
                        }
                    }
                }

                // Digit block: 1–9, then . 0 Cancel.
                VStack(spacing: spacing) {
                    digitRow(["1", "2", "3"], cell: cell)
                    digitRow(["4", "5", "6"], cell: cell)
                    digitRow(["7", "8", "9"], cell: cell)
                    HStack(spacing: spacing) {
                        key(width: cell, height: rowHeight) {
                            onDecimal()
                        } label: {
                            glyph(".")
                        }
                        key(width: cell, height: rowHeight) {
                            onDigit("0")
                        } label: {
                            glyph("0")
                        }
                        key(width: cell, height: rowHeight) {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.dsSubhead)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                // Right column: ⌫ (top, spans 2) and ✓ (bottom, spans 2).
                VStack(spacing: spacing) {
                    backspaceKey(width: cell)
                    saveKey(width: cell)
                }
            }
        }
        .frame(height: totalHeight)
        .frame(maxWidth: 420)          // iPad: cap width…
        .frame(maxWidth: .infinity)    // …and centre the capped block.
    }

    // MARK: - Rows / special keys

    private func digitRow(_ digits: [Character], cell: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(digits, id: \.self) { d in
                key(width: cell, height: rowHeight) {
                    onDigit(d)
                } label: {
                    glyph(String(d))
                }
            }
        }
    }

    private func backspaceKey(width: CGFloat) -> some View {
        keyShape(fill: Theme.card)
            .overlay(
                Image(systemName: "delete.left")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.text)
            )
            .frame(width: width, height: tallHeight)
            .contentShape(Rectangle())
            .onTapGesture { tap(); onBackspace() }
            .onLongPressGesture(minimumDuration: 0.4) { tap(); onClear() }
    }

    private func saveKey(width: CGFloat) -> some View {
        Button {
            tap(); onSave()
        } label: {
            keyShape(fill: Theme.accent)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .frame(width: width, height: tallHeight)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.4)
    }

    // MARK: - Key builder

    private func key(
        width: CGFloat,
        height: CGFloat,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button {
            tap(); action()
        } label: {
            keyShape(fill: Theme.card)
                .overlay(label())
                .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }

    private func keyShape(fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill)
    }

    private func glyph(_ s: String) -> some View {
        Text(s)
            .font(.dsTitle)
            .fontWeight(.medium)
            .monospacedDigit()
            .foregroundStyle(Theme.text)
    }

    private func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private extension CalcOperator {
    /// Top-to-bottom order down the keypad's operator column.
    static var orderedForKeypad: [CalcOperator] { [.divide, .multiply, .subtract, .add] }
}
#endif
