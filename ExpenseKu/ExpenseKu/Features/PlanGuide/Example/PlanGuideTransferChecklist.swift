//
//  PlanGuideTransferChecklist.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideTransferChecklist: View {
    let rows: [TransferRow]

    var body: some View {
        PlanGuideCard(header: AppLocalization.string(.transferChecklistOfSent(String(TransferLines.sentCount(rows)),
                                                                              String(rows.count)))) {
            ForEach(rows) { row in
                TransferRowView(row: row, onOpen: {})
            }
        }
        .planGuideTarget(.transferChecklist, radius: Metric.cardRadius)
    }
}
