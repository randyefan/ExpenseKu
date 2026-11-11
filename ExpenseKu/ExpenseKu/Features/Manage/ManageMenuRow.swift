//
//  ManageMenuRow.swift
//  ExpenseKu
//
//  One entry point on the Manage tab: icon, title, a live count, and a chevron.
//  The rows share a card (ManageView stacks them with hairlines between), so this
//  supplies no card of its own.
//

import SwiftUI

struct ManageMenuRow: View {
    let title: String
    let systemImage: String
    let subtitle: String
    var tint: Color? = nil
    var accessory: String = "chevron.right"

    var body: some View {
        HStack(spacing: 12) {
            if let tint {
                CategoryIcon(symbol: systemImage, tint: tint, size: Metric.iconSize)
            } else {
                CategoryIcon(name: title, systemImage: systemImage, size: Metric.iconSize)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: accessory)
                .font(.dsSubhead.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

#Preview {
    VStack(spacing: 0) {
        ManageMenuRow(title: "Categories", systemImage: "folder.fill",
                      subtitle: AppLocalization.string(.categoryCount(3)))
        Divider().overlay(Theme.hairline)
        ManageMenuRow(title: "People", systemImage: "person.2.fill",
                      subtitle: AppLocalization.string(.personCount(1)))
    }
    .cardStyle()
    .padding()
    .appBackground()
}
