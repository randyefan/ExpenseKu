//
//  ExpenseKuApp.swift
//  ExpenseKu
//
//  Created by Randy Efan Jayaputra on 09/08/26.
//

import SwiftUI
import SwiftData

/// The outcome of bringing the store up: the container, plus whether it is the ephemeral
/// fallback. Callers need both — an ephemeral store behaves normally right up until the
/// app exits, so the UI has to say so rather than let the owner log into it unaware.
struct StoreBootstrap {
    let container: ModelContainer
    /// True when the primary store could not be opened and everything lives in memory,
    /// meaning nothing logged this launch survives it.
    let isEphemeral: Bool

    /// Opens the primary CloudKit-mirrored store, falling back to an in-memory one when
    /// that is genuinely impossible — an unsigned test host, or a device not signed into
    /// iCloud.
    static func make() -> StoreBootstrap {
        // Declared through the versioned schema so the store always records which version
        // it is; see Models/ExpenseKuSchema.swift.
        let schema = Schema(versionedSchema: ExpenseKuSchemaV1.self)

        // Primary store: persistent, CloudKit-mirrored via the container in
        // ExpenseKu.entitlements (cloudKitDatabase defaults to .automatic).
        let persistent = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: ExpenseKuMigrationPlan.self,
                configurations: [persistent]
            )
            return StoreBootstrap(container: container, isEphemeral: false)
        } catch {
            // Never fail silently here. The fallback below keeps nothing, so this branch
            // decides whether the owner's expenses survive: a failed migration would
            // otherwise present as a blank app that quietly discards a day of logging.
            // Traps in debug so a broken migration can't ship unnoticed — but not under
            // XCTest, where the unsigned host makes this path expected.
            print("[ExpenseKu] Persistent store unavailable, falling back to memory: \(error)")
            if !isRunningTests {
                assertionFailure("Persistent store unavailable: \(error)")
            }
        }

        // Launch rather than crash — but the owner gets told, via `isEphemeral`.
        let inMemory = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: [inMemory])
            return StoreBootstrap(container: container, isEphemeral: true)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// True inside an XCTest run, where the test host is unsigned and the persistent
    /// store is legitimately unavailable — so the debug trap above must not fire.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

extension EnvironmentValues {
    /// True when the app is running on the ephemeral in-memory store, so nothing the
    /// owner logs will survive relaunch. Read by RootView to warn them.
    @Entry var isEphemeralStore = false
}

@main
struct ExpenseKuApp: App {
    private let store = StoreBootstrap.make()

    init() {
        AppFont.registerIfNeeded()
        Theme.configureBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.isEphemeralStore, store.isEphemeral)
        }
        .modelContainer(store.container)
    }
}
