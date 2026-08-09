//
//  ExpenseKuApp.swift
//  ExpenseKu
//
//  Created by Randy Efan Jayaputra on 09/08/26.
//

import SwiftUI
import SwiftData

@main
struct ExpenseKuApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self,
            Person.self,
        ])

        // Primary store: persistent, CloudKit-mirrored via the container in
        // ExpenseKu.entitlements (cloudKitDatabase defaults to .automatic).
        let persistent = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [persistent]) {
            return container
        }

        // Fallback: if the persistent/CloudKit store can't be created — e.g. an
        // unsigned test host or a device not signed into iCloud — launch with an
        // in-memory store rather than crashing.
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [inMemory])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
