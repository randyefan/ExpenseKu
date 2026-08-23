//
//  EmptyChartMessage.swift
//  ExpenseKu
//
//  Stands in for a chart when the selected period has nothing to plot.
//

import SwiftUI

struct EmptyChartMessage: View {
    var body: some View {
        Text("No spending in this period.")
            .font(.dsSubhead)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
