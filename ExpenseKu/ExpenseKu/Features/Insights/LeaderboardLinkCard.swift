//
//  LeaderboardLinkCard.swift
//  ExpenseKu
//
//  The row at the foot of Insights that pushes the People leaderboard.
//

import SwiftUI

struct LeaderboardLinkCard: View {
    var body: some View {
        NavigationLink(value: InsightsView.Destination.leaderboard) {
            HStack(spacing: 12) {
                CategoryIcon(name: "people", systemImage: "person.2.fill", size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("People leaderboard")
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Text("Who you spend with")
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
        .buttonStyle(.plain)
    }
}
