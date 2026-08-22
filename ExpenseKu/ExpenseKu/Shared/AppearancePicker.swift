//
//  AppearancePicker.swift
//  ExpenseKu
//
//  The color + icon customization used when creating/renaming a Category or
//  Account. A curated pastel palette (on-brand, dark-mode safe) and a grid of SF
//  Symbols, each with an "Auto" choice that clears the override and falls back to
//  the name-derived look. Purely presentational — it writes to two bindings.
//

import SwiftUI

/// The fixed set of swatches and glyphs offered to the owner.
nonisolated enum AppearancePalette {
    /// Twelve evenly-spread hues, authored through the same pastel recipe as the
    /// auto tints so a picked swatch matches its "Auto" neighbours.
    static let hues: [Double] = [
        0.00, 0.04, 0.08, 0.12, 0.15, 0.32,
        0.42, 0.50, 0.56, 0.72, 0.83, 0.92,
    ]

    /// The stored value for each swatch: the light-mode pastel hex.
    static let swatches: [String] = hues.map {
        HexColor.hexString(hue: $0, saturation: 0.28, brightness: 0.96)
    }

    /// A curated glyph set covering the common spend categories and payment
    /// sources. Superset of `CategoryIcon.symbol(for:)`'s table.
    static let symbols: [String] = [
        "fork.knife", "cup.and.saucer.fill", "bag.fill", "cart.fill",
        "car.fill", "fuelpump.fill", "tram.fill", "airplane",
        "house.fill", "bolt.fill", "wifi", "drop.fill",
        "cross.case.fill", "heart.fill", "dumbbell.fill", "pawprint.fill",
        "tshirt.fill", "gamecontroller.fill", "film.fill", "book.fill",
        "gift.fill", "creditcard.fill", "banknote.fill", "wallet.pass.fill",
        "phone.fill", "graduationcap.fill", "wineglass.fill", "tag.fill",
    ]
}

/// A color-swatch grid + icon grid with a live preview. Selecting the leading
/// "Auto" cell clears the override (binding → nil).
struct AppearancePickerView: View {
    @Binding var colorHex: String?
    @Binding var iconName: String?

    /// Seeds the preview + the "Auto" fallbacks so they read as they will in-app.
    let previewName: String
    /// The glyph used when no icon is chosen (name-derived for categories, the
    /// card glyph for accounts).
    let autoSymbol: String

    private let cell: CGFloat = 44
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: cell), spacing: 12)] }

    private var previewSymbol: String { iconName ?? autoSymbol }
    private var previewTint: Color { Theme.categoryTint(hex: colorHex, seed: previewName) }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.cardGap) {
            CategoryIcon(symbol: previewSymbol, tint: previewTint, size: 72)
                .frame(maxWidth: .infinity)

            SectionHeaderText("Color")
            LazyVGrid(columns: columns, spacing: 12) {
                autoColorCell
                ForEach(AppearancePalette.swatches, id: \.self) { hex in
                    colorCell(hex)
                }
            }

            SectionHeaderText("Icon")
            LazyVGrid(columns: columns, spacing: 12) {
                autoIconCell
                ForEach(AppearancePalette.symbols, id: \.self) { symbol in
                    iconCell(symbol)
                }
            }
        }
    }

    // MARK: Color cells

    private func colorCell(_ hex: String) -> some View {
        Button {
            colorHex = hex
        } label: {
            Circle()
                .fill(Theme.categoryTint(hex: hex, seed: previewName))
                .frame(width: cell, height: cell)
                .overlay(selectionRing(isSelected: colorHex == hex))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(hex)")
        .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
    }

    private var autoColorCell: some View {
        Button {
            colorHex = nil
        } label: {
            Circle()
                .fill(Theme.categoryTint(previewName))
                .frame(width: cell, height: cell)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: cell * 0.34, weight: .semibold))
                        .foregroundStyle(Theme.text.opacity(0.55))
                )
                .overlay(selectionRing(isSelected: colorHex == nil))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Automatic color")
        .accessibilityAddTraits(colorHex == nil ? .isSelected : [])
    }

    // MARK: Icon cells

    private func iconCell(_ symbol: String) -> some View {
        Button {
            iconName = symbol
        } label: {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.textSecondary.opacity(0.1))
                .frame(width: cell, height: cell)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: cell * 0.4, weight: .semibold))
                        .foregroundStyle(iconName == symbol ? Theme.accent : Theme.text.opacity(0.7))
                )
                .overlay(selectionRing(isSelected: iconName == symbol, cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
        .accessibilityAddTraits(iconName == symbol ? .isSelected : [])
    }

    private var autoIconCell: some View {
        Button {
            iconName = nil
        } label: {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.textSecondary.opacity(0.1))
                .frame(width: cell, height: cell)
                .overlay(
                    Image(systemName: autoSymbol)
                        .font(.system(size: cell * 0.4, weight: .semibold))
                        .foregroundStyle(Theme.text.opacity(0.7))
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                )
                .overlay(selectionRing(isSelected: iconName == nil, cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Automatic icon")
        .accessibilityAddTraits(iconName == nil ? .isSelected : [])
    }

    // MARK: Selection ring

    @ViewBuilder
    private func selectionRing(isSelected: Bool, cornerRadius: CGFloat? = nil) -> some View {
        if isSelected {
            let shape = RoundedRectangle(cornerRadius: cornerRadius ?? cell / 2, style: .continuous)
            shape
                .stroke(Theme.accent, lineWidth: 2.5)
                .padding(-3)
        }
    }
}
