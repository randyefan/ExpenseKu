//
//  FromEarlierCaption.swift
//  ExpenseKu
//

import SwiftUI

/// "→ Rp 18.500.000 from earlier" under an envelope's legend (set-aside.md §4.6). The glyph
/// is the violet arrow every forward-moving rupiah carries — paid-early tag, totals rows.
struct FromEarlierCaption: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.forward")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.plan)
                .accessibilityHidden(true)
            Text(text)
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
