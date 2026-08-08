//
//  NameEditorView.swift
//  ExpenseKu
//
//  Reusable add/rename editor for name-based entities. On save it runs the
//  ADR-0002 duplicate check and, on a case-insensitive name match, prompts the
//  owner instead of silently reusing or blindly creating a duplicate.
//

import SwiftUI
import SwiftData

struct NameEditorView<T: NamedEntity>: View {
    let title: String
    /// Non-nil when renaming an existing entity; nil when adding a new one.
    let editing: T?
    /// Creates a fresh, uninserted entity when the owner commits a new name.
    let makeNew: () -> T
    /// Called with the entity the owner settled on — the newly created one, the
    /// renamed one, or an existing duplicate they chose to reuse.
    let onCommit: (T) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var duplicate: T?

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
        _name = State(initialValue: editing?.name ?? "")
    }

    var body: some View {
        Form {
            TextField("Name", text: $name)
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: attemptSave)
                    .disabled(NameKey.normalized(name).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .confirmationDialog(
            duplicate.map { "“\($0.name)” already exists." } ?? "",
            isPresented: Binding(get: { duplicate != nil }, set: { if !$0 { duplicate = nil } }),
            titleVisibility: .visible
        ) {
            if let dup = duplicate {
                Button("Use “\(dup.name)”") { onCommit(dup); dismiss() }
                Button("Create new anyway") { save(into: makeNew()) }
                Button("Cancel", role: .cancel) { duplicate = nil }
            }
        }
    }

    private func attemptSave() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let dup = existingEntity(T.self, matching: trimmed, in: context, excluding: editing) {
            duplicate = dup
            return
        }
        save(into: editing ?? makeNew())
    }

    private func save(into entity: T) {
        if entity.modelContext == nil { context.insert(entity) }
        entity.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        onCommit(entity)
        dismiss()
    }
}
