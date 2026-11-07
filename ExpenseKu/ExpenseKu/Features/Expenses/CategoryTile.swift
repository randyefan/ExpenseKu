//
//  CategoryTile.swift
//  ExpenseKu
//
//  One cell of the editor's Category grid: the icon over the name.
//

import SwiftUI

struct CategoryTile<Icon: View>: View {
    let name: String
    let isSelected: Bool
    var isMuted = false
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(spacing: 5) {
            icon
            Text(name)
                .font(.dsCaption).fontWeight(.semibold)
                .foregroundStyle(isMuted ? Theme.textSecondary : Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: Metric.rowRadius)
                .fill(isSelected ? Theme.accent.opacity(0.12) : Theme.card)
                .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
        }
        .contentShape(.rect(cornerRadius: Metric.rowRadius))
    }
}
