//
//  AmountField.swift
//  ExpenseKu
//
//  Whole-rupiah amount entry that formats with grouping separators *live*, while
//  the field is being edited (e.g. "1000000" → "1,000,000"). SwiftUI's TextField
//  won't reliably reflect a reformat performed during active editing, so on iOS
//  this wraps a UITextField and reformats in its `editingChanged` action. macOS
//  falls back to a plain formatted TextField (not the primary logging surface).
//

import SwiftUI

/// Formats a whole-rupiah amount with grouping separators; "" for zero so the
/// field shows its placeholder.
private func groupedRupiah(_ value: Decimal) -> String {
    value > 0 ? value.formatted(.number.precision(.fractionLength(0))) : ""
}

struct AmountField: View {
    @Binding var amount: Decimal
    /// Auto-focus and raise the keyboard when the field appears (adding flow).
    var autoFocus: Bool = false

    var body: some View {
        #if os(iOS)
        CurrencyUITextField(amount: $amount, autoFocus: autoFocus)
            .fixedSize()
        #else
        TextField("0", value: $amount, format: .number.precision(.fractionLength(0)))
            .multilineTextAlignment(.center)
            .fixedSize()
        #endif
    }
}

#if os(iOS)
import UIKit

/// UITextField wrapper: reformats on every keystroke so grouping separators
/// appear as the user types, and writes the parsed value back to `amount`.
private struct CurrencyUITextField: UIViewRepresentable {
    @Binding var amount: Decimal
    var autoFocus: Bool

    func makeCoordinator() -> Coordinator { Coordinator(amount: $amount) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.textColor = UIColor(Theme.text)
        field.tintColor = UIColor(Theme.accent)
        field.font = Self.heroFont
        field.attributedPlaceholder = NSAttributedString(
            string: "0",
            attributes: [
                .foregroundColor: UIColor(Theme.textSecondary),
                .font: Self.heroFont,
            ]
        )
        field.text = groupedRupiah(amount)
        field.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentCompressionResistancePriority(.required, for: .horizontal)
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )

        if autoFocus {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        }
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        // Only overwrite when the external value genuinely differs from what's
        // shown, so we never fight the user mid-edit (editingChanged keeps the
        // binding in sync, so these are equal during typing).
        let shownValue = Decimal(string: (field.text ?? "").filter(\.isNumber)) ?? 0
        if shownValue != amount {
            field.text = groupedRupiah(amount)
        }
    }

    /// Plus Jakarta Sans, hero size, bold, monospaced digits, Dynamic-Type scaled.
    private static var heroFont: UIFont {
        let size: CGFloat = 30
        let base = UIFont(name: AppFont.family, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .bold)
        let bold = base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor
        let monoDigits = bold.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector,
            ]]
        ])
        let font = UIFont(descriptor: monoDigits, size: size)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }

    final class Coordinator: NSObject {
        private let amount: Binding<Decimal>
        init(amount: Binding<Decimal>) { self.amount = amount }

        @objc func editingChanged(_ field: UITextField) {
            let value = Decimal(string: (field.text ?? "").filter(\.isNumber)) ?? 0
            amount.wrappedValue = value
            let formatted = groupedRupiah(value)
            if field.text != formatted {
                field.text = formatted
                let end = field.endOfDocument
                field.selectedTextRange = field.textRange(from: end, to: end)
            }
        }
    }
}
#endif
