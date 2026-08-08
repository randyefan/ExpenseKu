//
//  RootView.swift
//  ExpenseKu
//
//  Top-level 3-tab shell (design.md §1). iPad/Mac sidebar refinement is deferred
//  to ticket 06; a TabView is correct on every platform for now. Expenses and
//  Insights are placeholders until tickets 05–08.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Expenses", systemImage: "list.bullet") }
            InsightsPlaceholderView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
            ManageView()
                .tabItem { Label("Manage", systemImage: "folder") }
        }
    }
}

private struct InsightsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Insights",
                systemImage: "chart.pie",
                description: Text("Charts & the people leaderboard arrive in tickets 07–08.")
            )
            .navigationTitle("Insights")
        }
    }
}
