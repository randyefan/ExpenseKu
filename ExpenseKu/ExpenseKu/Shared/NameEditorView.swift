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
    /// Optional extra fields shown below the name (e.g. the appearance picker).
    let accessory: AnyView?
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
        accessory: AnyView? = nil,
        applyExtras: @escaping (T) -> Void = { _ in },
        debugPrefill: String? = nil
    ) {
        self.title = title
        self.editing = editing
        self.makeNew = makeNew
        self.onCommit = onCommit
        self.accessory = accessory
        self.applyExtras = applyExtras
        self.debugPrefill = debugPrefill
        _name = State(initialValue: debugPrefill ?? editing?.name ?? "")
    }

    /// The lowercase noun for the entity kind, derived from the screen title
    /// ("New Category" → "category"), for the duplicate explanation copy.
    private var entityNoun: String {
        title
            .replacingOccurrences(of: "New ", with: "")
            .replacingOccurrences(of: "Rename ", with: "")
            .lowercased()
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
                    duplicatePrompt(dup)
                }

                if let accessory {
                    accessory
                }

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

    /// Inline duplicate prompt (ADR-0002): explain the clash, then offer the same
    /// three choices as before — reuse the existing entity, create a duplicate
    /// anyway, or back out.
    @ViewBuilder
    private func duplicatePrompt(_ dup: T) -> some View {
        VStack(spacing: Metric.cardGap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("“\(dup.name)” already exists")
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                    Text("You already have a \(entityNoun) with this name.")
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .cardStyle()

            Button {
                onCommit(dup); dismiss()
            } label: {
                Text("Use existing")
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Metric.cardRadius))
            }

            Button {
                save(into: makeNew())
            } label: {
                Text("Create new anyway")
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Metric.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Metric.cardRadius)
                            .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
                    )
            }

            Button("Cancel") { duplicate = nil }
                .font(.dsBody)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 2)
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
