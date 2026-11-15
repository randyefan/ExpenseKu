//
//  PlanGuideTransferSheetExample.swift
//  ExpenseKu
//
//  TransferSheet's body for Jago, drawn from the same parts and the same TransferPick
//  (plan-guide-visual.md §4.5, step 4.2). The sheet itself writes through its model context
//  and holds the choice as its own state, so the guide composes its parts instead and
//  passes the choice in from the sample.
//

import SwiftData
import SwiftUI

struct PlanGuideTransferSheetExample: View {
    let row: TransferRow
    let liburanChosen: Bool
    let liburanID: PersistentIdentifier

    var body: some View {
        let chosen = Set(row.members.map(\.id).filter { liburanChosen || $0 != liburanID })
        let pick = TransferPick(row: row, chosen: chosen)

        VStack(alignment: .leading, spacing: Metric.cardGap) {
            HStack(spacing: 8) {
                AccountPlate(style: row.plate)
                Text(appLocalized: .transferTo(row.accountName))
                    .font(.dsHeadline).bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            PlanGuideCard(header: pick.sendTitle) {
                ForEach(pick.toSend) { member in
                    TransferPickRowView(member: member, isChosen: pick.isChosen(member), onToggle: {})
                        .planGuideTarget(member.id == liburanID ? .liburanPick : .rowBody)
                }
            }

            PlanGuideCard {
                TransferAdjustmentRow(adjustment: row.adjustment, note: pick.adjustmentNote)
                TransferFigureRow(title: pick.figureTitle, amount: pick.figure, isNow: true)
                    .planGuideTarget(.transferNow)
            }

            TransferRecordButton(title: pick.recordEntry.title, isEnabled: pick.canRecord, action: {})
                .planGuideTarget(.movedButton, radius: 26)
        }
        .padding(Metric.cardPadding)
        .background(Theme.surface.opacity(0.5), in: .rect(cornerRadius: Metric.cardRadius + 4))
    }
}
