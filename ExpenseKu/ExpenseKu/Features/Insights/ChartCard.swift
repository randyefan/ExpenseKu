//
//  ChartCard.swift
//  ExpenseKu
//
//  The card every Insights chart sits in: a section header, an optional accessory on
//  the right, and the chart below. The accessory is generic rather than an `AnyView`
//  so SwiftUI keeps the type information it uses to tell an updated card from a
//  replaced one; `EmptyView` is the no-accessory case.
//

import SwiftUI

struct ChartCard<Accessory: View, Content: View>: View {
    let title: String
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.cardGap) {
            HStack {
                SectionHeaderText(title)
                Spacer()
                accessory
            }
            content
        }
        .cardStyle()
    }
}

extension ChartCard where Accessory == EmptyView {
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, accessory: { EmptyView() }, content: content)
    }
}
