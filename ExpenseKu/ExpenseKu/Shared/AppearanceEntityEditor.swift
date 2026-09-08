//
//  AppearanceEntityEditor.swift
//  ExpenseKu
//
//  Add/rename editor for the entities that carry a customizable appearance
//  (Category, Account). Wraps the shared `NameEditorView` — inheriting its
//  ADR-0002 duplicate handling — and layers the colour + icon workbench on top,
//  stamping the owner's choices onto the entity on save.
//
//  Both the stage and the workbench are rebuilt from the live name, so "Auto" is
//  never an abstraction: type "Kopi" and the cup appears before the field is
//  even left.
//

import SwiftUI
import SwiftData

/// A named entity whose icon color + glyph the owner can customize.
protocol AppearanceEntity: NamedEntity {
    var colorHex: String? { get set }
    var iconName: String? { get set }
    /// The glyph shown when no icon is chosen, for a (possibly in-progress) name.
    nonisolated static func autoSymbol(forName name: String) -> String
}

extension Category: AppearanceEntity {
    nonisolated static func autoSymbol(forName name: String) -> String { CategoryIcon.symbol(for: name) }
}

extension Account: AppearanceEntity {
    nonisolated static func autoSymbol(forName name: String) -> String { Account.defaultSymbol }
}

struct AppearanceEntityEditor<T: AppearanceEntity>: View {
    let title: String
    let editing: T?
    let makeNew: () -> T
    var onCommit: (T) -> Void

    @State private var colorHex: String?
    @State private var iconName: String?

    /// DEBUG screenshot support — see `NameEditorView.debugPrefill`.
    private let debugPrefill: String?

    init(
        title: String,
        editing: T? = nil,
        makeNew: @escaping () -> T,
        debugPrefill: String? = nil,
        onCommit: @escaping (T) -> Void = { _ in }
    ) {
        self.title = title
        self.editing = editing
        self.makeNew = makeNew
        self.onCommit = onCommit
        self.debugPrefill = debugPrefill
        _colorHex = State(initialValue: editing?.colorHex)
        _iconName = State(initialValue: editing?.iconName)
    }

    var body: some View {
        NameEditorView(
            title: title,
            editing: editing,
            makeNew: makeNew,
            onCommit: onCommit,
            stage: { name in
                EntityStage(
                    mark: .symbol(iconName ?? T.autoSymbol(forName: name)),
                    tint: Theme.categoryTint(hex: colorHex, seed: name),
                    name: name,
                    placeholder: "New \(T.noun.capitalized)",
                    caption: caption,
                    onShuffle: shuffle
                )
            },
            workbench: { name in
                AppearanceWorkbench(
                    colorHex: $colorHex,
                    iconName: $iconName,
                    previewName: name,
                    autoSymbol: T.autoSymbol(forName: name)
                )
            },
            tint: { Theme.categoryTint(hex: colorHex, seed: $0) },
            applyExtras: { entity in
                entity.colorHex = colorHex
                entity.iconName = iconName
            },
            debugPrefill: debugPrefill
        )
    }

    private var caption: String {
        let colour = colorHex == nil ? "Automatic colour" : "Custom colour"
        let icon = iconName == nil ? "automatic icon" : "custom icon"
        return "\(T.noun.capitalized) · \(colour), \(icon)"
    }

    private func shuffle() {
        withAnimation(Motion.snap) {
            colorHex = AppearancePalette.swatches.randomElement()
            iconName = AppearancePalette.symbols.randomElement()
        }
    }
}
