//
//  ManageMenuRow.swift
//  ExpenseKu
//
//  One entry point on the Manage tab: icon, title, a live count, and a chevron.
//

import SwiftUI

struct ManageMenuRow: View {
    let title: String
    let systemImage: String
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(name: title, systemImage: systemImage, size: Metric.iconSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.dsSubhead.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        ManageMenuRow(title: "Categories", systemImage: "folder.fill",
                      subtitle: "^[3 category](inflect: true)")
        ManageMenuRow(title: "People", systemImage: "person.2.fill",
                      subtitle: "^[1 person](inflect: true)")
    }
    .padding()
    .warmBackground()
}
