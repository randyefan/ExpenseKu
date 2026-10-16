//
//  ReadableListMargins.swift
//  ExpenseKu — DesignSystem
//
//  The `List` counterpart of `readableColumn()`. A List cannot simply be framed
//  narrower: its scroll gesture would then end at the column's edge, leaving the
//  iPad's side margins dead to a swipe or a trackpad. Widening the content margins
//  keeps the scroll view full width and only centres what it draws.
//

import SwiftUI

private struct ReadableListMargins: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private var margin: CGFloat {
        max(0, (width - Metric.readableWidth) / 2) + Metric.screenPadding
    }
}

extension View {
    func readableListMargins() -> some View {
        modifier(ReadableListMargins())
    }
}
