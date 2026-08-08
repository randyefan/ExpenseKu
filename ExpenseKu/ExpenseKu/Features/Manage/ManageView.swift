//
//  ManageView.swift
//  ExpenseKu
//
//  The "Manage" tab: entry points to the Categories and People screens.
//

import SwiftUI

struct ManageView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ManageCategoriesView()
                } label: {
                    Label("Categories", systemImage: "folder")
                }
                NavigationLink {
                    ManagePeopleView()
                } label: {
                    Label("People", systemImage: "person.2")
                }
            }
            .navigationTitle("Manage")
        }
    }
}
