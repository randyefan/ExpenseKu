//
//  ManageView.swift
//  ExpenseKu
//
//  The "Manage" tab: entry points to the Categories, Groups, People and Accounts
//  screens, each a menu row with a live count, and to Receipt reading, whose row says
//  where the model is (docs/prd/receipt-reading.md §4.10).
//
//  Groups joined when the cycle plan did. PRD §8 lists Manage as otherwise unchanged
//  but also gives Category an optional Group — and §9.6 requires Group names to be
//  de-duplicated "exactly as for Category and Person", which is only possible if the
//  owner can create and rename them.
//

import SwiftUI
import SwiftData

struct ManageView: View {
    enum Destination: Hashable { case categories, groups, people, accounts, receiptReading }

    @Query private var categories: [Category]
    @Query private var groups: [CategoryGroup]
    @Query private var people: [Person]
    @Query private var accounts: [Account]
    @State private var path: [Destination] = []
    @Environment(ReceiptModelStore.self) private var receiptModel

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Metric.cardGap) {
                    VStack(spacing: 0) {
                        NavigationLink(value: Destination.categories) {
                            ManageMenuRow(title: "Categories", systemImage: "folder.fill",
                                          subtitle: "^[\(categories.count) category](inflect: true)")
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.groups) {
                            ManageMenuRow(title: "Groups", systemImage: "tray.full.fill",
                                          subtitle: "^[\(groups.count) group](inflect: true)")
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.people) {
                            ManageMenuRow(title: "People", systemImage: "person.2.fill",
                                          subtitle: "^[\(people.count) person](inflect: true)")
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.accounts) {
                            ManageMenuRow(title: "Accounts", systemImage: "creditcard.fill",
                                          subtitle: "^[\(accounts.count) account](inflect: true)")
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.receiptReading) {
                            ManageMenuRow(title: "Receipt reading", systemImage: "text.viewfinder",
                                          subtitle: LocalizedStringKey(receiptModel.phase.subtitle),
                                          tint: Theme.accent)
                        }
                        .buttonStyle(.pressableRow)
                    }
                    .cardStyle()
                    .reveal(0)

                    AppVersionFooter()
                        .reveal(1)
                }
                .padding(Metric.screenPadding)
                .readableColumn()
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Manage")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .categories: ManageCategoriesView()
                case .groups: ManageGroupsView()
                case .people: ManagePeopleView()
                case .accounts: ManageAccountsView()
                case .receiptReading: ReceiptReadingView()
                }
            }
        }
        .task {
            #if DEBUG
            switch DebugLaunch.startScreen {
            case "categories": path = [.categories]
            case "groups": path = [.groups]
            case "people": path = [.people]
            case "accounts": path = [.accounts]
            case "receipt-reading": path = [.receiptReading]
            default: break
            }
            #endif
        }
    }
}
