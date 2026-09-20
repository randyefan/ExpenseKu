//
//  RootView.swift
//  ExpenseKu
//
//  Top-level 3-tab shell (design.md §1). iPad sidebar refinement is deferred
//  to ticket 06; a TabView is correct on every size class for now.
//

import SwiftUI
import CoreData
import SwiftData

struct RootView: View {
    enum AppTab: Hashable { case expenses, insights, manage }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.isEphemeralStore) private var isEphemeralStore
    @State private var selection: AppTab = .expenses
    #if DEBUG
    @State private var debugScreen: DebugScreen?
    #endif

    var body: some View {
        TabView(selection: $selection) {
            Tab("Expenses", systemImage: "list.bullet", value: AppTab.expenses) {
                ExpensesView()
            }
            Tab("Insights", systemImage: "chart.pie", value: AppTab.insights) {
                InsightsView()
            }
            Tab("Manage", systemImage: "folder", value: AppTab.manage) {
                ManageView()
            }
        }
        .tint(Theme.accent)
        .safeAreaInset(edge: .top) {
            if isEphemeralStore { EphemeralStoreBanner() }
        }
        #if DEBUG
        .fullScreenCover(item: $debugScreen) { screen in
            DebugHarness(screen: screen.name)
        }
        #endif
        .task {
            Person.reconcileMe(in: modelContext)
            // Auto items materialise here, lazily: iOS does not run this in the
            // background, so an Auto expense appears the first time the app is
            // opened after its due day passes (ADR-0007).
            PlanMaintenance.run(in: modelContext)
            #if DEBUG
            applyDebugLaunch()
            #endif
        }
        .task {
            // CloudKit merged changes from another device — re-check the "Me"
            // singleton and heal any duplicate that sync just introduced.
            let changes = NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange)
            for await _ in changes {
                Person.reconcileMe(in: modelContext)
                PlanMaintenance.run(in: modelContext)
            }
        }
    }

    #if DEBUG
    private func applyDebugLaunch() {
        DebugLaunch.seedIfNeeded(modelContext)

        switch DebugLaunch.startTab {
        case "insights": selection = .insights
        case "manage": selection = .manage
        case "expenses": selection = .expenses
        default: break
        }

        switch DebugLaunch.startScreen {
        case "calendar", "calendar-day", "search", "search-empty",
             "plan", "plan-next", "plan-dormant", "plan-list":
            // In-tab state, not a cover: ExpensesView's own task flips the lens
            // or prefills the query.
            selection = .expenses
        case "leaderboard", "person-detail":
            selection = .insights
        case "categories", "people", "accounts", "groups":
            selection = .manage
        default:
            break
        }

        if let screen = DebugLaunch.startScreen, DebugScreen.coverScreens.contains(screen) {
            debugScreen = DebugScreen(name: screen)
        }
    }
    #endif
}

#if DEBUG
/// A `-startScreen` value that opens as a full-screen cover rather than in-tab state.
struct DebugScreen: Identifiable, Hashable {
    let name: String
    var id: String { name }

    static let coverScreens: Set<String> = [
        "editor", "picker-category", "picker-people", "picker-account", "name-duplicate",
        "settings", "category-editor", "account-editor", "person-editor", "group-editor",
    ]
}
#endif
