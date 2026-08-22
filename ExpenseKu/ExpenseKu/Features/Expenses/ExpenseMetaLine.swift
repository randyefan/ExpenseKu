//
//  ExpenseMetaLine.swift
//  ExpenseKu
//
//  The quiet grey line under an expense's category: which account it came from and
//  who was there. Either half is omitted when unset.
//

import SwiftUI

struct ExpenseMetaLine: View {
    let accountName: String?
    let peopleNames: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let accountName {
                Label(accountName, systemImage: "creditcard")
                    .lineLimit(1)
            }
            if !peopleNames.isEmpty {
                Label(peopleNames, systemImage: "person.2")
                    .lineLimit(1)
            }
        }
        .labelStyle(MetaLabelStyle())
        .font(.dsCaption)
        .foregroundStyle(Theme.textSecondary)
    }
}

private struct MetaLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}
