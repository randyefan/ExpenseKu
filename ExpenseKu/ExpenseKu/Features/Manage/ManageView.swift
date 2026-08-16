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
                    menuRow(.categories, title: "Categories", systemImage: "folder.fill",
                            subtitle: "^[\(categories.count) category](inflect: true)")
                    menuRow(.people, title: "People", systemImage: "person.2.fill",
                            subtitle: "^[\(people.count) person](inflect: true)")
                    menuRow(.accounts, title: "Accounts", systemImage: "creditcard.fill",
                            subtitle: "^[\(accounts.count) account](inflect: true)")
                    footer
                }
                .padding(Metric.screenPadding)
            }
            .background(Theme.bg)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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

    private var footer: some View {
        VStack(spacing: 2) {
            Text("Made By REJ ❤️")
                .font(.dsCaption).fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)
            Text("Version \(appVersion)")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metric.cardGap)
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func menuRow(_ destination: Destination, title: String, systemImage: String, subtitle: LocalizedStringKey) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 12) {
                CategoryIcon(name: title, systemImage: systemImage, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Text(subtitle)
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
