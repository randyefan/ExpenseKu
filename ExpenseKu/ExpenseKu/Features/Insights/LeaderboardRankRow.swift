//
//  LeaderboardRankRow.swift
//  ExpenseKu
//
//  One row of the People leaderboard: rank, avatar, name, how many shared expenses,
//  and the total credited to them. Only the top rank takes the coral accent.
//

import SwiftUI

struct LeaderboardRankRow: View {
    let rank: Int
    let entry: PersonSpend

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.dsBody).bold()
                .monospacedDigit()
                .foregroundStyle(rank == 1 ? Theme.accent : Theme.textSecondary)
                .frame(minWidth: 20, alignment: .center)

            PersonAvatar(name: entry.person.name, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.person.name)
                    .font(.dsBody).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
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
        .cardStyle()
    }
}
