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

// MARK: - Person avatar (initial in a soft circle)

struct PersonAvatar: View {
    let name: String
    var size: CGFloat = Metric.iconSize
    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }
    var body: some View {
        Circle()
            .fill(Theme.textSecondary.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.jakarta(size * 0.38)).fontWeight(.semibold)
                    .foregroundStyle(Theme.text.opacity(0.7))
            )
    }
}

// MARK: - "New …" add row (pastel + circle + accent label)

struct PickerAddRow: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.textSecondary.opacity(0.12))
                .frame(width: Metric.iconSize, height: Metric.iconSize)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                )
            Text(title)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.accent)
            Spacer()
        }
    }
}

// MARK: - Payday stepper ("− value +", gray minus / coral plus)

struct PaydayStepper: View {
    @Binding var payday: Int
    var accessibilityTitle: String = "Monthly Start Date"

    var body: some View {
        HStack(spacing: 0) {
            button(systemImage: "minus", tint: Theme.textSecondary, enabled: payday > Payday.range.lowerBound) {
                payday = max(Payday.range.lowerBound, payday - 1)
            }
            Text("\(payday)")
                .font(.dsBody).fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .frame(minWidth: 40)
            button(systemImage: "plus", tint: Theme.accent, enabled: payday < Payday.range.upperBound) {
                payday = min(Payday.range.upperBound, payday + 1)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(Theme.textSecondary.opacity(0.1), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue("Day \(payday)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: payday = min(Payday.range.upperBound, payday + 1)
            case .decrement: payday = max(Payday.range.lowerBound, payday - 1)
            @unknown default: break
            }
        }
    }

    private func button(systemImage: String, tint: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.dsBody.weight(.semibold))
                .foregroundStyle(enabled ? tint : Theme.textSecondary.opacity(0.4))
                .frame(width: 36, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Segmented toggle (coral active pill on a muted track)

/// A small two-or-more segment switch in the Warm Cards language: a muted capsule
/// track with the active segment filled coral (the reserved "selected state" use).
/// A stock `.pickerStyle(.segmented)` can't take the coral fill cleanly, hence this.
struct SegmentedToggle<Value: Hashable>: View {
    struct Segment: Identifiable {
        let value: Value
        let title: String
        let systemImage: String
        var id: Value { value }

        init(_ value: Value, title: String, systemImage: String) {
            self.value = value
            self.title = title
            self.systemImage = systemImage
        }
    }

    @Binding var selection: Value
    let segments: [Segment]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Label(segment.title, systemImage: segment.systemImage)
                        .font(.dsSubhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule().fill(Theme.accent)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(segment.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background(Theme.textSecondary.opacity(0.1), in: Capsule())
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

/// The circular accent "+" button used in toolbars. Rendered with the system's
/// prominent circular button so it stays a true circle inside the toolbar's own
/// button chrome (a custom fixed-size Circle background gets clipped there).
private struct AccentCircleButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        // On Mac (the app ships as "Designed for iPad", so it's still a pure
        // iOS binary — no compile-time `os(macOS)`/`macCatalyst` flag fires) the
        // toolbar strips the prominent button's fill/tint and only a faint glyph
        // shows. Detect that at runtime and draw the coral circle explicitly.
        if runningOnMac {
            content
                .labelStyle(.iconOnly)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Theme.accent, in: Circle())
                .buttonStyle(.plain)
        } else {
            content
                .labelStyle(.iconOnly)
                .font(.body.weight(.bold))
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Theme.accent)
        }
    }

    private var runningOnMac: Bool {
        let info = ProcessInfo.processInfo
        return info.isiOSAppOnMac || info.isMacCatalystApp
    }
}

extension View {
    /// Styles a toolbar `Button` (with a `Label`) as the accent "+" circle.
    func accentCircleButton() -> some View { modifier(AccentCircleButton()) }
}
