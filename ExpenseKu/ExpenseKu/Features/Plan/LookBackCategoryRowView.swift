//
//  LookBackCategoryRowView.swift
//  ExpenseKu
//
//  The reviewed cycle's Outside plan spending in one Category, with the menu that
//  plans it here (look-back.md §5.2, §6.2, frames AB2–AB3).
//

import SwiftUI
import SwiftData

struct LookBackCategoryRowView: View {
    let row: LookBackCategoryRow
    let mark: LookBackMark?
    let month: String
    let planMonth: String
    let envelopes: [PlanItem]
    let onNew: (PlanItemKind) -> Void
    let onAddTo: (PlanItem) -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            icon
            LookBackRowBody(
                name: row.name,
                amountLine: LookBackCopy.spendLine(row.total, count: row.count),
                caption: mark?.caption(planMonth: planMonth) ?? row.caption,
                isDone: mark != nil
            )
            action
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var icon: some View {
        if let category = row.category {
            CategoryIcon(category: category, size: Metric.rowIconSize)
        } else {
            CategoryIcon(name: row.name, systemImage: "questionmark", size: Metric.rowIconSize)
        }
    }

    @ViewBuilder
    private var action: some View {
        if let mark {
            Button(action: onUndo) {
                LookBackActionPill(style: .done(mark.label))
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel(AppLocalization.string(.undo(mark.caption(planMonth: planMonth))))
        } else if row.canAdd {
            Menu {
                Section(LookBackCopy.menuTitle(row.name, total: row.total, month: month)) {
                    Button { onNew(.envelope) } label: {
                        Text(appLocalized: .newEnvelope)
                        Text(row.total.formattedIDR())
                        Image(systemName: "tray")
                    }
                    Button { onNew(.fixed) } label: {
                        Text(appLocalized: .newFixedItem)
                        Text(row.total.formattedIDR())
                        Image(systemName: "circle")
                    }
                }
                if !envelopes.isEmpty {
                    Section(LookBackCopy.addToEnvelope) {
                        ForEach(envelopes, id: \.persistentModelID) { envelope in
                            Button(AppLocalization.string(.addTo(envelope.name)), systemImage: "plus") { onAddTo(envelope) }
                        }
                    }
                }
            } label: {
                LookBackActionPill(style: .addMenu)
            }
            .accessibilityLabel(AppLocalization.string(.addNamedItem(row.name)))
        }
    }
}
