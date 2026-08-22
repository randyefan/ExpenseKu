//
//  AppearanceEntityEditor.swift
//  ExpenseKu
//
//  Add/rename editor for the entities that carry a customizable appearance
//  (Category, Account). Wraps the shared `NameEditorView` — inheriting its
//  ADR-0002 duplicate handling — and layers the color + icon picker on top,
//  stamping the owner's choices onto the entity on save.
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

    init(
        title: String,
        editing: T? = nil,
        makeNew: @escaping () -> T,
        onCommit: @escaping (T) -> Void = { _ in }
    ) {
        self.title = title
        self.editing = editing
        self.makeNew = makeNew
        self.onCommit = onCommit
        _colorHex = State(initialValue: editing?.colorHex)
        _iconName = State(initialValue: editing?.iconName)
    }

    var body: some View {
        NameEditorView(
            title: title,
            editing: editing,
            makeNew: makeNew,
            onCommit: onCommit,
            accessory: {
                AppearancePickerView(
                    colorHex: $colorHex,
                    iconName: $iconName,
                    previewName: editing?.name ?? "",
                    autoSymbol: T.autoSymbol(forName: editing?.name ?? "")
                )
            },
            applyExtras: { entity in
                entity.colorHex = colorHex
                entity.iconName = iconName
            }
        )
    }
}
