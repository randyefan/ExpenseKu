//
//  ManageView.swift
//  ExpenseKu
//
//  The "Manage" tab: entry points to the Categories and People screens.
//

import SwiftUI

struct ManageView: View {
    enum Destination: Hashable { case categories, people }

    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: Destination.categories) {
                    Label("Categories", systemImage: "folder")
                }
                NavigationLink(value: Destination.people) {
                    Label("People", systemImage: "person.2")
                }
            }
            .navigationTitle("Manage")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .categories: ManageCategoriesView()
                case .people: ManagePeopleView()
                }
            }
        }
        .task {
            #if DEBUG
            switch DebugLaunch.startScreen {
            case "categories": path = [.categories]
            case "people": path = [.people]
            default: break
            }
            #endif
        }
    }
}
