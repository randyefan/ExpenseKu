//
//  RootView.swift
//  ExpenseKu
//
//  Top-level 3-tab shell (design.md §1). iPad/Mac sidebar refinement is deferred
//  to ticket 06; a TabView is correct on every platform for now.
//

import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case expenses, insights, manage }

    @Environment(\.modelContext) private var modelContext
    @State private var selection: Tab = .expenses
    #if DEBUG
    @State private var debugScreen: String?
    private static let debugScreens: Set<String> = [
        "editor", "picker-category", "picker-people", "picker-account", "name-duplicate"
    ]
    #endif

    var body: some View {
        TabView(selection: $selection) {
            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "list.bullet") }
                .tag(Tab.expenses)
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
                .tag(Tab.insights)
            ManageView()
                .tabItem { Label("Manage", systemImage: "folder") }
                .tag(Tab.manage)
        }
        .tint(Theme.accent)
        #if DEBUG
        .fullScreenCover(isPresented: Binding(
            get: { debugScreen != nil },
            set: { if !$0 { debugScreen = nil } }
        )) {
            if let debugScreen { DebugHarness(screen: debugScreen) }
        }
        #endif
        .task {
            #if DEBUG
            DebugLaunch.seedIfNeeded(modelContext)
            switch DebugLaunch.startTab {
            case "insights": selection = .insights
            case "manage": selection = .manage
            case "expenses": selection = .expenses
            default: break
            }
            if let screen = DebugLaunch.startScreen, RootView.debugScreens.contains(screen) {
                debugScreen = screen
            }
            #endif
        }
    }
}
