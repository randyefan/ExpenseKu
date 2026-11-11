//
//  QuickEntrySection.swift
//  ExpenseKu
//
//  A labelled band of the expense editor: WHEN, CATEGORY, PEOPLE. The label sits in the
//  screen gutter while the content may run edge to edge (a chip rail).
//

import SwiftUI

struct QuickEntrySection<Accessory: View, Content: View>: View {
    let title: String
    var isRequired = false
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isRequired ? AppLocalization.string(.required(title)) : title)
                    .textCase(.uppercase)
                    .font(.dsCaption).fontWeight(.semibold)
                    .tracking(0.5)
                    .foregroundStyle(isRequired ? Theme.accentText : Theme.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                accessory
            }
            .padding(.horizontal, Metric.screenPadding + 4)
            content
        }
    }
}

extension QuickEntrySection where Accessory == EmptyView {
    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(title: title, isRequired: isRequired, accessory: { EmptyView() }, content: content)
    }
}
