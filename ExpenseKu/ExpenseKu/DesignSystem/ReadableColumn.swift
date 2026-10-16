//
//  ReadableColumn.swift
//  ExpenseKu — DesignSystem
//
//  Caps a screen's single column of cards at `Metric.readableWidth` and centres it, so
//  on an iPad rows do not stretch until the chevron sits a screen away from its label.
//  A no-op on iPhone, which is always narrower than the cap.
//

import SwiftUI

extension View {
    func readableColumn() -> some View {
        frame(maxWidth: Metric.readableWidth)
            .frame(maxWidth: .infinity)
    }
}
