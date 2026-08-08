//
//  PlatformModifiers.swift
//  ExpenseKu
//
//  Small cross-platform shims so multiplatform views compile on macOS, where
//  some iOS-only modifiers (e.g. keyboardType) don't exist.
//

import SwiftUI

extension View {
    /// Applies the decimal number pad on iOS; a no-op elsewhere.
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
