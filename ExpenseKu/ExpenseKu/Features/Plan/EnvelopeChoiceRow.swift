//
//  EnvelopeChoiceRow.swift
//  ExpenseKu
//

import SwiftUI

struct EnvelopeChoiceRow: View {
    let title: String
    let detail: String
    var detailIsOver = false
    let symbol: String
    let tint: Color
    let isChosen: Bool
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: 12) {
                CategoryIcon(symbol: symbol, tint: tint, size: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.dsBody)
                        .foregroundStyle(Theme.text)
                    Text(detail)
                        .font(.dsCaption)
                        .foregroundStyle(detailIsOver ? Theme.negative : Theme.textSecondary)
                }
                Spacer(minLength: 8)
                if isChosen {
                    Image(systemName: "checkmark")
                        .font(.dsBody.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(.rect)
        }
        .listRowBackground(Theme.card)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}
