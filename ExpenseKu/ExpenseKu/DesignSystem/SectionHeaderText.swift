//
//  SectionHeaderText.swift
//  ExpenseKu — DesignSystem
//
//  The uppercase grey label that heads a day or a section.
//

import SwiftUI

struct SectionHeaderText: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.dsCaption)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.5)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeaderText("Spending")
        SectionHeaderText("Thu, 6 August")
    }
    .padding()
    .warmBackground()
}
