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
            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "list.bullet") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
            ManageView()
                .tabItem { Label("Manage", systemImage: "folder") }
        }
    }
}
