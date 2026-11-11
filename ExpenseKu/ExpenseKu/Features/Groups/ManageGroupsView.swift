//
//  ManageGroupsView.swift
//  ExpenseKu
//
//  CRUD for groups — the coarse buckets above Category that the plan's percentage
//  table reads (frame H2).
//
//  A Group is user data, not a fixed enum (PRD §9.10): the six spreadsheet buckets are
//  seed values, so this gets the same add, rename, swipe-delete, empty state and
//  duplicate-name handling as Categories, Accounts and People. Delete relies on the
//  .nullify rule — the member categories survive, merely ungrouped (ADR-0001).
//

import SwiftUI
import SwiftData

struct ManageGroupsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CategoryGroup.name) private var groups: [CategoryGroup]
    @State private var editor: EditorTarget?

    /// The six buckets the spreadsheet used. Offered once, from the empty state, and
    /// never inserted silently: this runs per device against a store with no unique
    /// constraints (ADR-0002), so an automatic seed would give a two-device owner
    /// twelve groups.
    private static var starters: [String] { [
        AppLocalization.string(.starterFixedObligations), AppLocalization.string(.starterLovelySupport), AppLocalization.string(.starterHousingLiving),
        AppLocalization.string(.starterEntertainmentLifestyle), AppLocalization.string(.starterPersonalCare), AppLocalization.string(.starterTransportationTravel),
    ] }

    var body: some View {
        List {
            ForEach(groups.enumerated(), id: \.element.id) { index, group in
                Button { editor = EditorTarget(group: group) } label: {
                    HStack(spacing: 12) {
                        CategoryIcon(name: group.name, systemImage: group.resolvedSymbol,
                                     colorHex: group.colorHex, size: Metric.rowIconSize)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Text(PlanCopy.counted((group.categories ?? []).count, .category))
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.pressableRow)
                .listRowBackground(Theme.card)
                .listRowSeparatorTint(Theme.hairline)
                .reveal(index)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .readableListMargins()
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(AppLocalization.string(.groups))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(group: nil) } label: {
                    Label(AppLocalization.string(.addGroup), systemImage: "plus")
                }
                .accentCircleButton()
            }
        }
        .overlay {
            if groups.isEmpty {
                emptyState
                    .padding(.vertical, 16)
            }
        }
        .sheet(item: $editor) { target in
            NavigationStack {
                GroupEditorView(editing: target.group)
            }
            .presentationBackground(Theme.bg)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Metric.cardGap) {
            EmptyStateView(
                title: AppLocalization.string(.noGroups),
                systemImage: "tray.full.fill",
                message: AppLocalization.string(.aGroupAnswersWhatMoneyIsForAboveTheCategoryThat)
            )
            Button(AppLocalization.string(.addTheSixStarterGroups), action: addStarters)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.accent, in: .capsule)
                .buttonStyle(.pressableCard)
        }
    }

    private func addStarters() {
        for name in Self.starters where existingEntity(CategoryGroup.self, matching: name, in: context) == nil {
            context.insert(CategoryGroup(name: name))
        }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(groups[index]) }
        try? context.save()
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let group: CategoryGroup?
    }
}
