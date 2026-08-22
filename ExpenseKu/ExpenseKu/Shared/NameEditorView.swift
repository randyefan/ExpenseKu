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

struct NameEditorView<T: NamedEntity, Accessory: View>: View {
    let title: String
    /// Non-nil when renaming an existing entity; nil when adding a new one.
    let editing: T?
    /// Creates a fresh, uninserted entity when the owner commits a new name.
    let makeNew: () -> T
    /// Called with the entity the owner settled on — the newly created one, the
    /// renamed one, or an existing duplicate they chose to reuse.
    let onCommit: (T) -> Void
    /// Extra fields shown below the name (e.g. the appearance picker); `EmptyView`
    /// when the entity has none.
    @ViewBuilder let accessory: Accessory
    /// Stamps extra owner choices onto the entity just before commit. Runs on the
    /// create / rename / "create anyway" paths — never when reusing an existing
    /// entity (that one keeps its own appearance).
    let applyExtras: (T) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var duplicate: T?

    /// DEBUG screenshot support: a name to prefill and immediately run the
    /// duplicate check against, so the inline prompt can be captured. Never set
    /// in the real UI.
    private let debugPrefill: String?

    init(
        title: String,
        editing: T? = nil,
        makeNew: @escaping () -> T,
        onCommit: @escaping (T) -> Void = { _ in },
        @ViewBuilder accessory: () -> Accessory,
        applyExtras: @escaping (T) -> Void = { _ in },
        debugPrefill: String? = nil
    ) {
        self.title = title
        self.editing = editing
        self.makeNew = makeNew
        self.onCommit = onCommit
        self.accessory = accessory()
        self.applyExtras = applyExtras
        self.debugPrefill = debugPrefill
        _name = State(initialValue: debugPrefill ?? editing?.name ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Name", text: $name)
                        .font(.dsTitle).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .onChange(of: name) { _, _ in duplicate = nil }
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(height: 2)
                }

                if let dup = duplicate {
                    DuplicateNamePrompt(
                        existingName: dup.name,
                        noun: T.noun,
                        onUseExisting: { onCommit(dup); dismiss() },
                        onCreateAnyway: { save(into: makeNew()) },
                        onCancel: { duplicate = nil }
                    )
                }

                accessory

                Spacer(minLength: 0)
            }
            .padding(Metric.screenPadding)
        }
        .background(Theme.bg)
        .onAppear { if debugPrefill != nil { attemptSave() } }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: attemptSave)
                    .disabled(NameKey.normalized(name).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
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
        applyExtras(entity)
        // Before onCommit, which hands the entity to the caller (often straight onto an
        // Expense): a persistent ID is only permanent once saved.
        try? context.save()
        onCommit(entity)
        dismiss()
    }
}

extension NameEditorView where Accessory == EmptyView {
    /// For entities with no extra fields — Person.
    init(
        title: String,
        editing: T? = nil,
        makeNew: @escaping () -> T,
        onCommit: @escaping (T) -> Void = { _ in },
        debugPrefill: String? = nil
    ) {
        self.init(
            title: title,
            editing: editing,
            makeNew: makeNew,
            onCommit: onCommit,
            accessory: { EmptyView() },
            debugPrefill: debugPrefill
        )
    }
}

