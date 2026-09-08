//
//  AppearancePicker.swift
//  ExpenseKu
//
//  The colour + icon workbench used when creating/renaming a Category, an Account
//  or a Person. Colour and icon are two panes of one segmented control rather
//  than two stacked sections, so the screen stays one glance tall and the swap
//  between them travels in the direction the segment moved.
//
//  Colour is a continuous hue dial that snaps to the twelve palette hues, backed
//  by quick-pick dots; icons are a searchable, grouped catalogue. Both keep an
//  "Auto" choice that clears the override and hands the look back to the name.
//
//  Purely presentational — it writes to two bindings.
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
    static let swatches: [String] = hues.map { hex(forHue: $0) }

    /// The storage form of any hue on the dial, authored through the swatch recipe
    /// so a dialled colour and a tapped swatch are the same kind of value.
    static func hex(forHue hue: Double) -> String {
        HexColor.hexString(hue: hue, saturation: 0.28, brightness: 0.96)
    }

    struct IconGroup: Identifiable {
        let title: String
        let symbols: [String]
        var id: String { title }
    }

    /// A curated glyph set covering the common spend categories and payment
    /// sources, grouped so a long catalogue stays scannable. Superset of
    /// `CategoryIcon.symbol(for:)`'s table.
    static let groups: [IconGroup] = [
        .init(title: "Food & drink", symbols: [
            "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
            "wineglass.fill", "birthday.cake.fill", "carrot.fill",
        ]),
        .init(title: "Shopping", symbols: [
            "bag.fill", "cart.fill", "tshirt.fill",
            "gift.fill", "tag.fill", "shippingbox.fill",
        ]),
        .init(title: "Getting around", symbols: [
            "car.fill", "fuelpump.fill", "tram.fill",
            "airplane", "bicycle", "bus.fill",
        ]),
        .init(title: "Home & bills", symbols: [
            "house.fill", "bolt.fill", "wifi",
            "drop.fill", "flame.fill", "trash.fill",
        ]),
        .init(title: "Health", symbols: [
            "cross.case.fill", "heart.fill", "dumbbell.fill",
            "pills.fill", "pawprint.fill", "leaf.fill",
        ]),
        .init(title: "Fun", symbols: [
            "gamecontroller.fill", "film.fill", "book.fill",
            "music.note", "ticket.fill", "camera.fill",
        ]),
        .init(title: "Money", symbols: [
            "creditcard.fill", "banknote.fill", "wallet.pass.fill",
            "building.columns.fill", "chart.line.uptrend.xyaxis", "arrow.left.arrow.right",
        ]),
        .init(title: "Work & study", symbols: [
            "briefcase.fill", "graduationcap.fill", "phone.fill",
            "desktopcomputer", "pencil.and.ruler.fill", "envelope.fill",
        ]),
    ]

    static let symbols: [String] = groups.flatMap(\.symbols)

    /// Indonesian and everyday words that don't appear in an SF Symbol's own name,
    /// so searching "bensin" or "kopi" finds the glyph it should.
    private static let aliases: [String: [String]] = [
        "fork.knife": ["makan", "food", "eat", "restaurant"],
        "cup.and.saucer.fill": ["kopi", "coffee", "cafe", "tea"],
        "takeoutbag.and.cup.and.straw.fill": ["takeaway", "delivery", "gofood"],
        "wineglass.fill": ["minum", "drink", "bar"],
        "birthday.cake.fill": ["kue", "ulang tahun", "party"],
        "carrot.fill": ["sayur", "vegetable", "grocery"],
        "bag.fill": ["belanja", "grocery", "shopping"],
        "cart.fill": ["belanja", "supermarket", "shop"],
        "tshirt.fill": ["baju", "clothes", "fashion"],
        "gift.fill": ["hadiah", "present", "donation"],
        "shippingbox.fill": ["paket", "parcel", "delivery"],
        "car.fill": ["mobil", "grab", "gojek", "taxi"],
        "fuelpump.fill": ["bensin", "fuel", "gas", "petrol"],
        "tram.fill": ["kereta", "train", "mrt"],
        "airplane": ["pesawat", "flight", "travel"],
        "bicycle": ["sepeda", "bike"],
        "bus.fill": ["bis", "transjakarta"],
        "house.fill": ["rumah", "rent", "kos", "sewa"],
        "bolt.fill": ["listrik", "electric", "power", "utility"],
        "wifi": ["internet", "wifi", "data"],
        "drop.fill": ["air", "water", "pdam"],
        "flame.fill": ["gas", "heating"],
        "trash.fill": ["sampah", "waste"],
        "cross.case.fill": ["obat", "medic", "doctor", "hospital"],
        "heart.fill": ["sehat", "health", "love"],
        "dumbbell.fill": ["gym", "olahraga", "fitness"],
        "pills.fill": ["obat", "vitamin", "pharmacy"],
        "pawprint.fill": ["hewan", "pet", "kucing", "anjing"],
        "leaf.fill": ["tanaman", "plant", "nature"],
        "gamecontroller.fill": ["game", "main"],
        "film.fill": ["film", "movie", "bioskop", "cinema"],
        "book.fill": ["buku", "book", "read"],
        "music.note": ["musik", "music", "spotify"],
        "ticket.fill": ["tiket", "event", "concert"],
        "camera.fill": ["kamera", "photo", "foto"],
        "creditcard.fill": ["kartu", "credit", "debit"],
        "banknote.fill": ["uang", "cash", "tunai"],
        "wallet.pass.fill": ["dompet", "wallet", "ewallet", "gopay", "ovo"],
        "building.columns.fill": ["bank", "tabungan", "savings"],
        "chart.line.uptrend.xyaxis": ["investasi", "invest", "saham", "stocks"],
        "arrow.left.arrow.right": ["transfer", "kirim"],
        "briefcase.fill": ["kerja", "work", "business"],
        "graduationcap.fill": ["sekolah", "school", "kuliah", "education"],
        "phone.fill": ["pulsa", "phone", "telepon"],
        "desktopcomputer": ["komputer", "computer", "laptop"],
        "pencil.and.ruler.fill": ["alat", "tools", "design"],
        "envelope.fill": ["surat", "mail", "post"],
    ]

    static func matches(_ symbol: String, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return true }
        if symbol.replacingOccurrences(of: ".", with: " ").contains(q) { return true }
        return aliases[symbol]?.contains { $0.contains(q) } ?? false
    }
}

// MARK: - Colour

/// The colour pane: a hue dial over quick-pick dots. Used on its own by the person
/// editor, which has no glyph to choose.
struct ColorWorkbench: View {
    @Binding var colorHex: String?
    /// Seeds the "Auto" choice so it shows the tint the name would produce. Live:
    /// it tracks the name field keystroke by keystroke.
    let previewName: String

    private let dot: CGFloat = 34


    private var dialHue: Binding<Double> {
        Binding(
            get: {
                if let colorHex, let hue = HexColor.hue(colorHex) { return hue }
                return resolvedAutoHue
            },
            set: { colorHex = AppearancePalette.hex(forHue: $0) }
        )
    }

    /// The hue the name alone would produce, so the dial starts where "Auto" is.
    private var resolvedAutoHue: Double {
        let hues: [Double] = [0.03, 0.09, 0.13, 0.33, 0.55, 0.72, 0.85]
        return hues[Theme.stableIndex(previewName, upperBound: hues.count)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HueDial(hue: dialHue,
                    snapPoints: AppearancePalette.hues,
                    isAuto: colorHex == nil)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7),
                      spacing: 12) {
                autoDot
                ForEach(AppearancePalette.swatches, id: \.self) { hex in
                    swatchDot(hex)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: colorHex)
    }

    private var autoDot: some View {
        Button {
            withAnimation(Motion.snap) { colorHex = nil }
        } label: {
            Circle()
                .fill(Theme.categoryTint(previewName))
                .frame(width: dot, height: dot)
                .overlay(
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: dot * 0.36, weight: .bold))
                        .foregroundStyle(Theme.onTint.opacity(0.8))
                )
                .overlay(selectionRing(colorHex == nil))
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel("Automatic colour")
        .accessibilityAddTraits(colorHex == nil ? .isSelected : [])
    }

    private func swatchDot(_ hex: String) -> some View {
        let isSelected = colorHex == hex
        return Button {
            withAnimation(Motion.snap) { colorHex = hex }
        } label: {
            Circle()
                .fill(Theme.categoryTint(hex: hex, seed: previewName))
                .frame(width: dot, height: dot)
                .overlay(selectionRing(isSelected))
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel("Colour \(hex)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func selectionRing(_ isSelected: Bool) -> some View {
        Circle()
            .stroke(Theme.text.opacity(isSelected ? 0.9 : 0), lineWidth: 2)
            .padding(-4)
            .scaleEffect(isSelected ? 1 : 0.8)
            .motion(Motion.snap, value: isSelected)
    }
}

// MARK: - Workbench

/// Colour and icon as two panes of one segmented control.
struct AppearanceWorkbench: View {
    @Binding var colorHex: String?
    @Binding var iconName: String?

    /// Seeds the "Auto" fallbacks so they read as they will in-app. Live: it
    /// tracks the name field keystroke by keystroke.
    let previewName: String
    /// The glyph used when no icon is chosen (name-derived for categories, the
    /// card glyph for accounts).
    let autoSymbol: String

    private enum Lens: Hashable { case color, icon }

    @State private var lens: Lens = .color
    @State private var pageEdge: Edge = .leading
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private let cell: CGFloat = 46
    private let markerInset: CGFloat = 4
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: cell), spacing: 12)] }

    private var previewTint: Color { Theme.categoryTint(hex: colorHex, seed: previewName) }

    private var lensBinding: Binding<Lens> {
        Binding(
            get: { lens },
            set: { next in
                pageEdge = next == .icon ? .leading : .trailing
                lens = next
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SegmentedToggle(
                selection: lensBinding,
                segments: [
                    .init(.color, title: "Colour", systemImage: "paintpalette.fill"),
                    .init(.icon, title: "Icon", systemImage: "square.grid.2x2.fill"),
                ]
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                switch lens {
                case .color: ColorWorkbench(colorHex: $colorHex, previewName: previewName)
                case .icon: iconPane
                }
            }
            .motionTransition(.page(towards: pageEdge))
        }
        .sensoryFeedback(.selection, trigger: iconName)
    }

    // MARK: - Icon pane

    private var iconPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField

            LazyVGrid(columns: columns, spacing: 12) {
                if query.isEmpty {
                    Section {
                        autoIconCell
                    } header: {
                        SectionHeaderText("From the name")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                ForEach(AppearancePalette.groups) { group in
                    let hits = group.symbols.filter { AppearancePalette.matches($0, query: query) }
                    if !hits.isEmpty {
                        Section {
                            ForEach(hits, id: \.self) { iconCell($0) }
                        } header: {
                            SectionHeaderText(group.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .motion(Motion.snap, value: query)

            if noMatches {
                Text("No icon matches “\(query)”.")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
    }

    private var noMatches: Bool {
        !query.isEmpty && !AppearancePalette.symbols.contains { AppearancePalette.matches($0, query: query) }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            TextField("Search icons", text: $query)
                .font(.dsBody)
                .foregroundStyle(Theme.text)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)

            if !query.isEmpty {
                Button {
                    withAnimation(Motion.snap) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .motionTransition(.opacity)
                .accessibilityLabel("Clear icon search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: Metric.rowRadius)
                .fill(Theme.surface)
                .stroke(Theme.accent.opacity(searchFocused ? 0.7 : 0), lineWidth: 1.5)
        }
        .motion(Motion.snap, value: searchFocused)
    }

    private func iconCell(_ symbol: String) -> some View {
        let isSelected = iconName == symbol
        return Button {
            withAnimation(Motion.snap) { iconName = symbol }
        } label: {
            glyphCell(symbol, isSelected: isSelected)
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel(symbol)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var autoIconCell: some View {
        let isSelected = iconName == nil
        return Button {
            withAnimation(Motion.snap) { iconName = nil }
        } label: {
            glyphCell(autoSymbol, isSelected: isSelected)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.accentText)
                        .padding(3)
                        .background(Theme.card, in: Circle())
                        .offset(x: 5, y: -5)
                }
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel("Automatic icon")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func glyphCell(_ symbol: String, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: Metric.rowRadius)
            .fill(Theme.surface)
            .frame(width: cell, height: cell)
            .background(iconMarker(isSelected: isSelected))
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: cell * 0.4, weight: .semibold))
                    .foregroundStyle(isSelected ? previewTint : Theme.text.opacity(0.7))
                    .motion(Motion.snap, value: isSelected)
            )
    }

    /// The icon marker wears the chosen colour, so the two panes read as one
    /// decision rather than two unrelated settings.
    private func iconMarker(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: Metric.rowRadius)
            .fill(previewTint.opacity(isSelected ? Theme.tintFillOpacity : 0))
            .stroke(Theme.accent.opacity(isSelected ? 1 : 0), lineWidth: 2.5)
            .padding(-markerInset)
            .scaleEffect(isSelected ? 1 : 0.88)
            .motion(Motion.snap, value: isSelected)
    }
}

#Preview {
    @Previewable @State var hex: String? = AppearancePalette.swatches[3]
    @Previewable @State var icon: String? = "cup.and.saucer.fill"
    return ScrollView {
        AppearanceWorkbench(colorHex: $hex, iconName: $icon,
                            previewName: "Kopi", autoSymbol: "cup.and.saucer.fill")
            .padding(Metric.screenPadding)
    }
    .appBackground()
}
