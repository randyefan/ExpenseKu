//
//  PersonEditorView.swift
//  ExpenseKu
//
//  Add/rename editor for a companion. A Person has no glyph to choose — an
//  initial is the avatar — so this is the name, a live stage, and the same colour
//  workbench the category and account editors use. Without it the screen is a
//  text field alone: nothing to interact with, and no way to tell two companions
//  apart on the leaderboard beyond whatever tint their name happened to hash to.
//
//  Leaving the colour on "Auto" keeps exactly that name-derived tint, so every
//  person who existed before the colour was addable looks unchanged.
//

import SwiftUI
import SwiftData

struct PersonEditorView: View {
    let title: String
    var editing: Person?
    var onCommit: (Person) -> Void = { _ in }

    @State private var colorHex: String?

    init(title: String, editing: Person? = nil, onCommit: @escaping (Person) -> Void = { _ in }) {
        self.title = title
        self.editing = editing
        self.onCommit = onCommit
        _colorHex = State(initialValue: editing?.colorHex)
    }

    var body: some View {
        NameEditorView(
            title: title,
            editing: editing,
            makeNew: { Person() },
            onCommit: onCommit,
            stage: { name in
                EntityStage(
                    mark: .initial(PersonAvatar.initial(for: name)),
                    tint: Theme.categoryTint(hex: colorHex, seed: name),
                    name: name,
                    placeholder: "New Person",
                    caption: colorHex == nil ? "Person · Automatic colour" : "Person · Custom colour",
                    onShuffle: shuffle
                )
            },
            workbench: { name in
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeaderText("Colour")
                    ColorWorkbench(colorHex: $colorHex, previewName: name)
                }
            },
            tint: { Theme.categoryTint(hex: colorHex, seed: $0) },
            applyExtras: { person in
                person.colorHex = colorHex
            }
        )
    }

    private func shuffle() {
        withAnimation(Motion.snap) {
            colorHex = AppearancePalette.swatches.randomElement()
        }
    }
}
