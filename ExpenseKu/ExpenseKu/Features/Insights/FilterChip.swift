//
//  FilterChip.swift
//  ExpenseKu
//
//  The "Label: value ⌄" pill that fronts each leaderboard filter menu.
//

import SwiftUI

struct FilterChip: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(label): \(value)")
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
            Image(systemName: "chevron.down")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Theme.card)
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        FilterChip(label: "Period", value: "All time")
        FilterChip(label: "Category", value: "All")
        FilterChip(label: "Account", value: "Bank Central Asia")
    }
    .padding()
    .warmBackground()
}
