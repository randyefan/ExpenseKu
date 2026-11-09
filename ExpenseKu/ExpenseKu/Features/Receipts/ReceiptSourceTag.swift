//
//  ReceiptSourceTag.swift
//  ExpenseKu
//
//  The small capsule under a To check card's date: Gemma AI or OCR, no AI
//  (docs/prd/reading-source.md §4.4, frame AI5).
//

import SwiftUI

struct ReceiptSourceTag: View {
    let source: ReceiptReadingSource

    var body: some View {
        Label(source.tag, systemImage: source.systemImage)
            .labelStyle(ReceiptSourceTagLabelStyle())
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(source.isAI ? Theme.accentText : Theme.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(source.isAI ? Theme.accent.opacity(Theme.tintFillOpacity) : Theme.surface, in: .capsule)
    }
}

private struct ReceiptSourceTagLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .imageScale(.small)
            configuration.title
        }
    }
}
