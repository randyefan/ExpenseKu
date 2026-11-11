//
//  LookBackRowBody.swift
//  ExpenseKu
//
//  The text column every Look back row shares: name, the amount line, and a caption
//  that turns green once the row has been acted on (look-back.md §6, frame AB4).
//

import SwiftUI

struct LookBackRowBody: View {
    let name: String
    let amountLine: String
    let caption: String?
    var isDone = false
    var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name.isEmpty ? AppLocalization.string(.untitled) : name)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(isDimmed ? Theme.textSecondary.opacity(0.6) : Theme.text)
                .lineLimit(1)
            Text(amountLine)
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary.opacity(isDimmed ? 0.6 : 1))
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(.dsCaption)
                    .foregroundStyle(isDone ? Theme.positive : Theme.textSecondary.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
