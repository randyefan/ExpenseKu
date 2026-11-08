//
//  ReceiptFieldRow.swift
//  ExpenseKu
//
//  A label and a value on the review card (frame AG7).
//

import SwiftUI

struct ReceiptFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            SectionHeaderText(label)
            Spacer(minLength: 8)
            Text(value)
                .font(.dsSubhead)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}
