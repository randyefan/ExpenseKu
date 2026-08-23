//
//  PickerAddRow.swift
//  ExpenseKu — DesignSystem
//
//  The "New …" row at the foot of each picker.
//

import SwiftUI

struct PickerAddRow: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.textSecondary.opacity(0.12))
                .frame(width: Metric.iconSize, height: Metric.iconSize)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: Metric.iconSize * 0.41, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            Text(title)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.accent)
            Spacer()
        }
    }
}

#Preview {
    PickerAddRow(title: "New Category")
        .padding()
        .warmBackground()
}
