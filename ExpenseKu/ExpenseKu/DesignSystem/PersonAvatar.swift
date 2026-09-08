//
//  PersonAvatar.swift
//  ExpenseKu — DesignSystem
//
//  A companion's initial in a soft circle, tinted from their name by the same
//  stable hash that tints categories — so a leaderboard of five people reads as
//  five people rather than five identical grey discs.
//

import SwiftUI

struct PersonAvatar: View {
    let name: String
    var size: CGFloat = Metric.iconSize

    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }

    private var tint: Color { Theme.categoryTint(name) }

    var body: some View {
        Circle()
            .fill(tint.opacity(Theme.tintFillOpacity))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.jakarta(size * 0.38)).fontWeight(.semibold)
                    .foregroundStyle(tint)
            )
    }
}

#Preview {
    HStack(spacing: Metric.cardGap) {
        PersonAvatar(name: "Tarisa")
        PersonAvatar(name: "Fadil")
        PersonAvatar(name: "Budi")
        PersonAvatar(name: "budi", size: 36)
        PersonAvatar(name: "  ", size: 36)
        PersonAvatar(name: "", size: 36)
    }
    .padding()
    .appBackground()
}
