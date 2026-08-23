//
//  CategoryIcon.swift
//  ExpenseKu — DesignSystem
//
//  The pastel circle standing for a category or an account. The glyph and tint come
//  from the owner's choice when set, otherwise from the name.
//

import SwiftUI

struct CategoryIcon: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = Metric.iconSize

    /// Explicit glyph + tint (used by the appearance picker's live preview).
    init(symbol: String, tint: Color, size: CGFloat = Metric.iconSize) {
        self.symbol = symbol
        self.tint = tint
        self.size = size
    }

    /// Name-seeded icon. `systemImage` overrides the inferred glyph; `colorHex`
    /// overrides the name-derived tint. Used for ad-hoc icons (people, "None") and
    /// as the base for the entity-aware initialisers below.
    init(name: String, systemImage: String? = nil, colorHex: String? = nil,
         size: CGFloat = Metric.iconSize) {
        self.symbol = systemImage ?? CategoryIcon.symbol(for: name)
        self.tint = Theme.categoryTint(hex: colorHex, seed: name)
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.41, weight: .semibold))
                    .foregroundStyle(Theme.text.opacity(0.65))
            )
    }

    /// Best-effort mapping from a category name to a representative SF Symbol.
    /// Purely cosmetic — falls back to a neutral tag so any name renders.
    nonisolated static func symbol(for name: String) -> String {
        let n = name.lowercased()
        let table: [(match: [String], symbol: String)] = [
            (["groc", "belanja", "market", "mart"], "bag.fill"),
            (["food", "makan", "dining", "dinner", "lunch", "resto", "restaurant"], "fork.knife"),
            (["coffee", "kopi", "snack", "cafe", "drink"], "cup.and.saucer.fill"),
            (["transport", "travel", "grab", "gojek", "taxi", "fuel", "bensin", "car"], "car.fill"),
            (["util", "listrik", "electric", "water", "gas", "internet", "wifi", "phone", "bill"], "bolt.fill"),
            (["home", "rent", "kos", "house", "sewa"], "house.fill"),
            (["health", "medic", "doctor", "obat", "pharmacy"], "cross.case.fill"),
            (["shop", "cloth", "fashion", "baju"], "cart.fill"),
            (["fun", "entertain", "movie", "game", "hobby"], "gamecontroller.fill"),
            (["gift", "donat", "charity"], "gift.fill"),
        ]
        for entry in table where entry.match.contains(where: n.contains) {
            return entry.symbol
        }
        return "tag.fill"
    }
}

extension CategoryIcon {
    /// A category rendered with its owner-chosen (or auto) icon and color.
    init(category: Category, size: CGFloat = Metric.iconSize) {
        self.init(symbol: category.resolvedSymbol,
                  tint: Theme.categoryTint(hex: category.colorHex, seed: category.name),
                  size: size)
    }

    /// An account rendered with its owner-chosen (or auto) icon and color.
    init(account: Account, size: CGFloat = Metric.iconSize) {
        self.init(symbol: account.resolvedSymbol,
                  tint: Theme.categoryTint(hex: account.colorHex, seed: account.name),
                  size: size)
    }
}

#Preview("Auto tints") {
    let names = ["Makan", "Kopi", "Transport", "Listrik", "Rent", "Obat", "Baju", "Gift", "Nonexistent"]
    return LazyVGrid(columns: Array(repeating: GridItem(), count: 4), spacing: Metric.cardGap) {
        ForEach(names, id: \.self) { name in
            VStack {
                CategoryIcon(name: name)
                Text(name).font(.dsCaption).foregroundStyle(Theme.textSecondary)
            }
        }
    }
    .padding()
    .warmBackground()
}

#Preview("Gelap") {
    let names = ["Makan", "Kopi", "Transport", "Listrik"]
    return HStack {
        ForEach(names, id: \.self) { CategoryIcon(name: $0) }
    }
    .padding()
    .warmBackground()
    .preferredColorScheme(.dark)
}
