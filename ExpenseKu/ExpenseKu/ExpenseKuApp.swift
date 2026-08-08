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
        // cloudKitDatabase defaults to .automatic, which mirrors to the private
        // CloudKit container declared in ExpenseKu.entitlements.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
