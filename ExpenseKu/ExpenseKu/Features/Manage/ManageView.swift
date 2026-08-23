//
//  ManageView.swift
//  ExpenseKu
//
//  The "Manage" tab: entry points to the Categories, People and Accounts
//  screens, each a Warm Cards menu row with a live count.
//

import SwiftUI
import SwiftData

struct ManageView: View {
    enum Destination: Hashable { case categories, people, accounts }

    @Query private var categories: [Category]
    @Query private var people: [Person]
    @Query private var accounts: [Account]
    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Metric.cardGap) {
                    NavigationLink(value: Destination.categories) {
                        ManageMenuRow(title: "Categories", systemImage: "folder.fill",
                                      subtitle: "^[\(categories.count) category](inflect: true)")
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: Destination.people) {
                        ManageMenuRow(title: "People", systemImage: "person.2.fill",
                                      subtitle: "^[\(people.count) person](inflect: true)")
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: Destination.accounts) {
                        ManageMenuRow(title: "Accounts", systemImage: "creditcard.fill",
                                      subtitle: "^[\(accounts.count) account](inflect: true)")
                    }
                    .buttonStyle(.plain)
                    AppVersionFooter()
                }
                .padding(Metric.screenPadding)
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Manage")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .categories: ManageCategoriesView()
                case .people: ManagePeopleView()
                case .accounts: ManageAccountsView()
                }
            }
        }
        .task {
            #if DEBUG
            switch DebugLaunch.startScreen {
            case "categories": path = [.categories]
            case "people": path = [.people]
            case "accounts": path = [.accounts]
            default: break
            }
            #endif
        }
    }
}
