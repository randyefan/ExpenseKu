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
    var systemImage: String = "tag.fill"
    var body: some View {
        Circle()
            .fill(Theme.categoryTint(name))
            .frame(width: Metric.iconSize, height: Metric.iconSize)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.text.opacity(0.65))
            )
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent)
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
