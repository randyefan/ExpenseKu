//
//  ReceiptCheckTag.swift
//  ExpenseKu
//
//  The small "Check" capsule after the Category on a receipt expense's row
//  (docs/prd/receipt-reading.md §4.7, frame AG2).
//

import SwiftUI

struct ReceiptCheckTag: View {
    var body: some View {
        Text("Check")
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(Theme.accentText)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Theme.accent.opacity(Theme.tintFillOpacity), in: .capsule)
            .accessibilityLabel("Needs checking")
    }
}
