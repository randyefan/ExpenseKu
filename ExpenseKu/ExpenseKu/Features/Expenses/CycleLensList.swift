//
//  CycleLensList.swift
//  ExpenseKu
//
//  The List chrome shared by all three cycle lenses. One modifier rather than three
//  copies: the lenses cross-fade into each other, so any difference between them
//  shows up as the header sliding mid-transition, which a still screenshot will not
//  catch.
//

import SwiftUI

extension View {
    /// Applies the chrome every cycle lens's `List` wears.
    ///
    /// The zeroed top margin is what keeps the header card at the same y as the
    /// empty-cycle state, which is a plain `ScrollView`: `.insetGrouped` otherwise
    /// insets its first section by 35pt and the card drops on every lens that has
    /// content.
    func cycleLensList() -> some View {
        self
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .environment(\.defaultMinListHeaderHeight, 0)
            .contentMargins(.horizontal, Metric.screenPadding, for: .scrollContent)
            .contentMargins(.top, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
    }
}
