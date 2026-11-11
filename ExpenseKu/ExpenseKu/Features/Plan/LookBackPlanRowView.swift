//
//  LookBackPlanRowView.swift
//  ExpenseKu
//
//  One of the reviewed cycle's plan items that the plan on screen lacks (look-back.md
//  §5.1, frame AB2). The kind glyph leads, as on DormantRow: a plan row here is a
//  reminder, not a checklist line, so it carries no Done control.
//

import SwiftUI

struct LookBackPlanRowView: View {
    let row: LookBackPlanRow
    let mark: LookBackMark?
    let planMonth: String
    let onAct: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.source.isEnvelope ? "tray" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(glyphTint)
                .frame(width: 26)
                .accessibilityHidden(true)

            LookBackRowBody(
                name: row.source.name,
                amountLine: row.amountLine,
                caption: mark?.caption(planMonth: planMonth) ?? row.caption,
                isDone: mark != nil,
                isDimmed: row.isUnused
            )

            Button(action: mark == nil ? onAct : onUndo) {
                LookBackActionPill(style: pillStyle)
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel(accessibilityLabel)
        }
        .padding(.vertical, 8)
    }

    private var glyphTint: Color {
        if row.isUnused { return Theme.textSecondary.opacity(0.35) }
        return row.source.isEnvelope ? Theme.plan : Theme.textSecondary.opacity(0.7)
    }

    private var pillStyle: LookBackActionPill.Style {
        if let mark { return .done(mark.label) }
        if case .wake = row.action { return .wake }
        return .add
    }

    private var accessibilityLabel: String {
        if let mark { return AppLocalization.string(.undoNamedChange(mark.label.lowercased(), row.source.name)) }
        if case .wake = row.action { return AppLocalization.string(.wakePlanItem(row.source.name)) }
        return AppLocalization.string(.addNamedItem(row.source.name))
    }
}
