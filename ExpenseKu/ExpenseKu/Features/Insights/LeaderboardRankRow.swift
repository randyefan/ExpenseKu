//
//  LeaderboardRankRow.swift
//  ExpenseKu
//
//  One row of the People leaderboard: rank, avatar, name, how many shared expenses,
//  the total credited to them, and a bar showing that total against the leader's.
//  Only the top rank takes the amber accent.
//
//  The bar is what makes the ranking readable at a glance — a column of figures
//  alone makes you compare digits to see whether second place is close or nowhere
//  near.
//

import SwiftUI

struct LeaderboardRankRow: View {
    let rank: Int
    let entry: PersonSpend
    /// This entry's total as a share of the leader's, 0…1.
    let fraction: Double
    var growth: Double = 1

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.dsBody).bold()
                    .monospacedDigit()
                    .foregroundStyle(rank == 1 ? Theme.accentText : Theme.textSecondary)
                    .frame(minWidth: 20, alignment: .center)

                PersonAvatar(name: entry.person.name, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.person.name)
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text("^[\(entry.sharedCount) expense](inflect: true)")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                MoneyText(entry.total, font: .dsBody, color: Theme.text)

                Image(systemName: "chevron.right")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            Capsule()
                .fill(Theme.textSecondary.opacity(0.12))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(rank == 1 ? Theme.accent : Theme.categoryTint(entry.person.name))
                            .frame(
                                width: max(6, proxy.size.width * min(max(fraction, 0), 1) * growth),
                                height: 6
                            )
                    }
                    .frame(height: 6)
                }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
