//
//  EnvelopeCategoriesPicker.swift
//  ExpenseKu
//
//  Picking what an envelope totals (frame F4).
//
//  A Category belongs to at most one envelope per plan (PRD §5.2), so two envelopes
//  can never count the same expense twice. Categories another envelope has already
//  claimed appear in their own section, **disabled and named** — not merely
//  unchecked, and not hidden. Hiding them would leave the owner hunting for "Makan";
//  showing them tappable would let the rule be broken and then have to be explained.
//
//  ADR-0002 means the store cannot enforce this, so the picker is where it lives.
//

import SwiftUI
import SwiftData

struct EnvelopeCategoriesPicker: View {
    @Binding var selection: [Category]
    let claims: [PersistentIdentifier: String]
    let envelopeName: String

    @Query(sort: \Category.name) private var categories: [Category]
    @Environment(\.dismiss) private var dismiss

    private var available: [Category] {
        categories.filter { claims[$0.persistentModelID] == nil }
    }

    private var claimed: [Category] {
        categories.filter { claims[$0.persistentModelID] != nil }
    }

    var body: some View {
        List {
            Section {
                ForEach(available) { category in
                    Button { toggle(category) } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(category: category, size: Metric.rowIconSize)
                            Text(category.name)
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 8)
                            Image(systemName: isSelected(category) ? "checkmark.circle.fill" : "circle")
                                .font(.dsBody)
                                .foregroundStyle(isSelected(category) ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.pressableRow)
                    .listRowBackground(Theme.card)
                    .accessibilityAddTraits(isSelected(category) ? [.isButton, .isSelected] : .isButton)
                }
            } header: {
                Text(headerText).textCase(nil)
            }

            if !claimed.isEmpty {
                Section {
                    ForEach(claimed) { category in
                        HStack(spacing: 12) {
                            CategoryIcon(category: category, size: Metric.rowIconSize)
                                .opacity(0.4)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.dsBody)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("already in \(claims[category.persistentModelID] ?? "")")
                                    .font(.dsCaption)
                                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "lock.fill")
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary.opacity(0.5))
                        }
                        .listRowBackground(Theme.card)
                        .accessibilityLabel(category.name)
                        .accessibilityValue("Already in \(claims[category.persistentModelID] ?? "another envelope")")
                    }
                } header: {
                    Text("Already in another envelope").textCase(nil)
                } footer: {
                    Text("A category belongs to one envelope per plan, so two envelopes can never count the same expense twice.")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.tint(Theme.accentText)
            }
        }
    }

    private var headerText: String {
        let name = envelopeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = name.isEmpty ? "this envelope" : "“\(name)”"
        return "Pick what \(subject) should total. \(selection.count) selected."
    }

    private func isSelected(_ category: Category) -> Bool {
        selection.contains { $0.persistentModelID == category.persistentModelID }
    }

    private func toggle(_ category: Category) {
        if let index = selection.firstIndex(where: { $0.persistentModelID == category.persistentModelID }) {
            selection.remove(at: index)
        } else {
            selection.append(category)
        }
    }
}
