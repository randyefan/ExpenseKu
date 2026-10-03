//
//  SpendBreakdownCard.swift
//  ExpenseKu
//
//  The drill-in's other dimension: a category's accounts or an account's categories.
//  Each row narrows the screen to it; the narrowed row takes a check and its siblings
//  dim but keep their figures (Flow K, K3).
//

import SwiftUI

struct SpendBreakdownCard: View {
    let title: String
    let rows: [SpendBreakdownRow]
    let narrowing: SpendSubject?
    let onTap: (SpendSubject) -> Void

    @State private var growth = ChartGrowth()

    private var maxTotal: Double { max(rows.map(\.total.doubleValue).max() ?? 1, 1) }

    private var hint: String {
        guard let narrowing, let row = rows.first(where: { $0.subject == narrowing }) else { return "Tap to narrow" }
        return "\(row.name) only"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeaderText(title)
                Spacer(minLength: 8)
                Text(hint)
                    .font(.dsCaption)
                    .foregroundStyle(narrowing == nil ? Theme.textSecondary.opacity(0.6) : Theme.accentText)
            }

            ForEach(rows) { row in
                let isNarrowed = row.subject == narrowing
                Button {
                    onTap(row.subject)
                } label: {
                    ProportionRow(
                        name: row.name,
                        value: row.total,
                        fraction: row.total.doubleValue / maxTotal,
                        tint: Theme.categoryTint(hex: row.colorHex, seed: row.name),
                        symbol: row.resolvedSymbol,
                        growth: growth.factor,
                        mark: isNarrowed ? .check : .chevron
                    )
                    .opacity(narrowing == nil || isNarrowed ? 1 : 0.35)
                    .contentShape(.rect)
                }
                .buttonStyle(.pressableRow)
                .accessibilityAddTraits(isNarrowed ? .isSelected : [])
            }
        }
        .cardStyle()
        .motion(Motion.snap, value: narrowing)
        .growsOnAppear(growth, trigger: rows.map(\.id))
    }
}
