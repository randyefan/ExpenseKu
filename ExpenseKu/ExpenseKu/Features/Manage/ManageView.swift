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
    @Environment(TourStore.self) private var tourStore
    @Environment(\.tour) private var tour
    @State private var showingTourMap = false
    @State private var pickedTourEntry: TourEntry?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Metric.cardGap) {
                    if tour == nil, tourStore.outcome != .finished {
                        TourManageCard(done: tourStore.progress.done) { showingTourMap = true }
                            .reveal(0)
                    }

                    VStack(spacing: 0) {
                        NavigationLink(value: Destination.categories) {
                            ManageMenuRow(title: AppLocalization.string(.categories), systemImage: "folder.fill",
                                          subtitle: AppLocalization.string(.categoryCount(categories.count)))
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.groups) {
                            ManageMenuRow(title: AppLocalization.string(.groups), systemImage: "tray.full.fill",
                                          subtitle: AppLocalization.string(.groupCount(groups.count)))
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.people) {
                            ManageMenuRow(title: AppLocalization.string(.people), systemImage: "person.2.fill",
                                          subtitle: AppLocalization.string(.personCount(people.count)))
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.accounts) {
                            ManageMenuRow(title: AppLocalization.string(.accounts), systemImage: "creditcard.fill",
                                          subtitle: AppLocalization.string(.accountCount(accounts.count)))
                        }
                        .buttonStyle(.pressableRow)
                        Divider().overlay(Theme.hairline)
                        NavigationLink(value: Destination.receiptReading) {
                            ManageMenuRow(title: AppLocalization.string(.receiptReading), systemImage: "text.viewfinder",
                                          subtitle: receiptModel.phase.subtitle,
                                          tint: Theme.accent)
                        }
                        .buttonStyle(.pressableRow)
                    }
                    .cardStyle()
                    .reveal(0)

                    LanguageMenu()
                        .reveal(1)

                    if tour == nil, tourStore.outcome == .finished {
                        Button { showingTourMap = true } label: {
                            ManageMenuRow(title: AppLocalization.string(.tourName), systemImage: "wallet.bifold.fill",
                                          subtitle: AppLocalization.string(.tourPlayAgain), tint: Theme.accent)
                        }
                        .buttonStyle(.pressableRow)
                        .cardStyle()
                        .reveal(2)
                    }

                    AppVersionFooter()
                        .reveal(2)
                }
                .padding(Metric.screenPadding)
                .readableColumn()
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(AppLocalization.string(.manage))
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
        .sheet(isPresented: $showingTourMap, onDismiss: openPickedTour) {
            TourChapterMapSheet(done: tourStore.progress.done) { pickedTourEntry = $0 }
                .presentationBackground(Theme.bg)
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

    private func openPickedTour() {
        guard let pickedTourEntry else { return }
        self.pickedTourEntry = nil
        tourStore.launch = TourLaunch(entry: pickedTourEntry, isReplay: true)
    }
}
