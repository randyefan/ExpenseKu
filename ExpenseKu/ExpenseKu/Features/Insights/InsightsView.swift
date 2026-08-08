//
//  InsightsView.swift
//  ExpenseKu
//
//  The Insights tab. For now it hosts the People leaderboard; the spend charts
//  (ticket 07) will join it here.
//

import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            PeopleLeaderboardView()
        }
    }
}
