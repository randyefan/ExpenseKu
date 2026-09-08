//
//  NameEditorView.swift
//  ExpenseKu
//
//  Reusable add/rename editor for name-based entities. On save it runs the
//  ADR-0002 duplicate check and, on a case-insensitive name match, prompts the
//  owner instead of silently reusing or blindly creating a duplicate.
//
//  The screen is a studio: the stage at the top is the thing being made, the
//  whole background carries its colour, and everything below is an input that
//  changes it. `stage` and `workbench` are handed the name as it currently stands
//  rather than a fixed snapshot, so a category becomes a coffee cup while "Kopi"
//  is still being typed.
//

import SwiftUI
import SwiftData

struct NameEditorView<T: NamedEntity, Stage: View, Workbench: View>: View {
    let title: String
    /// Non-nil when renaming an existing entity; nil when adding a new one.
    let editing: T?
    /// Creates a fresh, uninserted entity when the owner commits a new name.
    let makeNew: () -> T
    /// Called with the entity the owner settled on — the newly created one, the
    /// renamed one, or an existing duplicate they chose to reuse.
    let onCommit: (T) -> Void
    /// The live subject above the name field, given the name as it stands.
    @ViewBuilder let stage: (String) -> Stage
    /// The controls below the name (colour, icon), given the name as it stands;
    /// `EmptyView` when the entity has none.
    @ViewBuilder let workbench: (String) -> Workbench
    /// The subject's current colour, used for the ambient wash and the save pill.
    let tint: (String) -> Color
    /// Stamps extra owner choices onto the entity just before commit. Runs on the
    /// create / rename / "create anyway" paths — never when reusing an existing
    /// entity (that one keeps its own appearance).
    let applyExtras: (T) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var duplicate: T?
    @FocusState private var nameFocused: Bool

    /// DEBUG screenshot support: a name to prefill and immediately run the
    /// duplicate check against, so the inline prompt can be captured. Never set
    /// in the real UI.
    private let debugPrefill: String?

    init(
        title: String,
        editing: T? = nil,
        makeNew: @escaping () -> T,
        onCommit: @escaping (T) -> Void = { _ in },
        @ViewBuilder stage: @escaping (String) -> Stage,
        @ViewBuilder workbench: @escaping (String) -> Workbench,
        tint: @escaping (String) -> Color = { Theme.categoryTint($0) },
        applyExtras: @escaping (T) -> Void = { _ in },
        debugPrefill: String? = nil
    ) {
        self.title = title
        self.editing = editing
        self.makeNew = makeNew
        self.onCommit = onCommit
        self.stage = stage
        self.workbench = workbench
        self.tint = tint
        self.applyExtras = applyExtras
        self.debugPrefill = debugPrefill
        _name = State(initialValue: debugPrefill ?? editing?.name ?? "")
    }

    /// The name as the entity would be saved with it.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { !NameKey.normalized(name).isEmpty }

    private var currentTint: Color { tint(trimmedName) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stage(trimmedName)
                    .reveal(0)

                nameField
                    .reveal(1)

                if let dup = duplicate {
                    DuplicateNamePrompt(
                        existingName: dup.name,
                        noun: T.noun,
                        onUseExisting: { onCommit(dup); dismiss() },
                        onCreateAnyway: { save(into: makeNew()) },
                        onCancel: { clearDuplicate() }
                    )
                    .motionTransition(.rise)
                }

                workbench(trimmedName)
                    .cardStyle()
                    .clipShape(.rect(cornerRadius: Metric.cardRadius))
                    .reveal(2)

                Spacer(minLength: 0)
            }
            .padding(Metric.screenPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ambientWash)
        .safeAreaInset(edge: .bottom) { savePill }
        .motion(Motion.settle, value: duplicate?.persistentModelID)
        .sensoryFeedback(.warning, trigger: duplicate?.persistentModelID) { $1 != nil }
        .onAppear { if debugPrefill != nil { attemptSave() } }
        // Adding starts on the keyboard — the owner tapped "+" to type a name.
        // Renaming does not: the name is already there and the picker is usually
        // what they came for.
        .task {
            guard debugPrefill == nil, editing == nil else { return }
            nameFocused = true
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Background

    private var ambientWash: some View {
        ZStack(alignment: .top) {
            Theme.bg
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: currentTint.opacity(0.26), location: 0.30),
                    .init(color: currentTint.opacity(0.06), location: 0.70),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 460)
            .blur(radius: 20)
        }
        .ignoresSafeArea()
        .motion(Motion.settle, value: currentTint)
    }

    // MARK: - Name

    /// The rule under the field carries the focus state: it sweeps to accent from
    /// the leading edge on focus and retracts the same way, which is the one place
    /// on this screen the keyboard's arrival is acknowledged.
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderText("Name")

            HStack(spacing: 8) {
                TextField(T.noun.capitalized, text: $name)
                    .font(.dsTitle).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                    .focused($nameFocused)
                    // Names here are proper nouns, often Indonesian; autocorrect
                    // "fixes" them into English words and the inline suggestion bar
                    // covers the colour rail while it does it.
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(attemptSave)
                    .onChange(of: name) { _, _ in clearDuplicate() }

                if !name.isEmpty {
                    Button {
                        withAnimation(Motion.snap) { name = "" }
                        nameFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .motionTransition(.opacity)
                    .accessibilityLabel("Clear name")
                }
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 2)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(height: 2)
                    .scaleEffect(x: nameFocused ? 1 : 0, anchor: .leading)
            }
            .motion(Motion.settle, value: nameFocused)
        }
        .contentShape(.rect)
        .onTapGesture { nameFocused = true }
    }

    // MARK: - Save

    private var savePill: some View {
        Button(action: attemptSave) {
            Text("Save")
                .font(.dsHeadline).fontWeight(.semibold)
                .foregroundStyle(canSave ? Theme.onTint : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    Capsule()
                        .fill(canSave ? currentTint : Theme.surface)
                }
        }
        .buttonStyle(.pressableCard)
        .disabled(!canSave)
        .padding(.horizontal, Metric.screenPadding)
        .padding(.top, 18)
        .padding(.bottom, 6)
        .background {
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg, Theme.bg],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
        .motion(Motion.settle, value: canSave)
        .motion(Motion.settle, value: currentTint)
    }

    // MARK: - Saving

    private func clearDuplicate() {
        guard duplicate != nil else { return }
        withAnimation(Motion.settle) { duplicate = nil }
    }

    private func attemptSave() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        if let dup = existingEntity(T.self, matching: trimmed, in: context, excluding: editing) {
            nameFocused = false
            withAnimation(Motion.settle) { duplicate = dup }
            return
        }
        save(into: editing ?? makeNew())
    }

    private func save(into entity: T) {
        if entity.modelContext == nil { context.insert(entity) }
        entity.name = trimmedName
        applyExtras(entity)
        // Before onCommit, which hands the entity to the caller (often straight onto an
        // Expense): a persistent ID is only permanent once saved.
        try? context.save()
        onCommit(entity)
        dismiss()
    }
}

extension NameEditorView where Stage == EmptyView, Workbench == EmptyView {
    /// For entities with neither a preview nor extra fields.
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
            stage: { _ in EmptyView() },
            workbench: { _ in EmptyView() },
            debugPrefill: debugPrefill
        )
    }
}
