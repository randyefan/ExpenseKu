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
    /// The owner's chosen tint; nil derives one from the name.
    var colorHex: String?
    var size: CGFloat = Metric.iconSize

    init(name: String, colorHex: String? = nil, size: CGFloat = Metric.iconSize) {
        self.name = name
        self.colorHex = colorHex
        self.size = size
    }

    init(person: Person, size: CGFloat = Metric.iconSize) {
        self.init(name: person.name, colorHex: person.colorHex, size: size)
    }

    /// The letter the avatar wears. Shared with the person editor's hero, so a
    /// companion looks the same while being named as they will in every list.
    nonisolated static func initial(for name: String) -> String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }

    private var initial: String { PersonAvatar.initial(for: name) }

    private var tint: Color { Theme.categoryTint(hex: colorHex, seed: name) }

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
