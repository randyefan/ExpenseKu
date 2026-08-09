//
//  Components.swift
//  ExpenseKu — DesignSystem
//
//  Reusable "Warm Cards" building blocks: card surface, section header, money
//  text, category icon, empty state, accent button. Behaviour-free styling only.
//

import SwiftUI

// MARK: - Card surface

struct CardStyle: ViewModifier {
    var padding: CGFloat = Metric.cardPadding
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    /// Elevated white/dark card with hairline border and rounded corners.
    func cardStyle(padding: CGFloat = Metric.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }

    /// Paints the warm canvas edge-to-edge behind this view.
    func warmBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }
}

// MARK: - Section header (uppercase gray day/section labels)

struct SectionHeaderText: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.dsCaption)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.5)
    }
}

// MARK: - Money

struct MoneyText: View {
    let amount: Decimal
    var font: Font = .dsBody
    var color: Color = Theme.text
    init(_ amount: Decimal, font: Font = .dsBody, color: Color = Theme.text) {
        self.amount = amount; self.font = font; self.color = color
    }
    var body: some View {
        Text(amount.formattedIDR())
            .font(font)
            .fontWeight(.bold)
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

// MARK: - Category icon (pastel circle)

struct CategoryIcon: View {
    let name: String
    var systemImage: String?
    var body: some View {
        Circle()
            .fill(Theme.categoryTint(name))
            .frame(width: Metric.iconSize, height: Metric.iconSize)
            .overlay(
                Image(systemName: systemImage ?? CategoryIcon.symbol(for: name))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.text.opacity(0.65))
            )
    }

    /// Best-effort mapping from a category name to a representative SF Symbol.
    /// Purely cosmetic — falls back to a neutral tag so any name renders.
    static func symbol(for name: String) -> String {
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

// MARK: - Empty state

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.textSecondary.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, 4)
            Text(title)
                .font(.dsTitle).fontWeight(.bold)
                .foregroundStyle(Theme.text)
            Text(message)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metric.screenPadding)
        .warmBackground()
    }
}

// MARK: - Accent button (the "+" style)

struct AccentCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .background(Theme.accent, in: Circle())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
