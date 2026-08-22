//
//  Payday.swift
//  ExpenseKu
//
//  The owner's payday anchor (day-of-month) for the "This pay period" filter.
//  Stored as a single value in NSUbiquitousKeyValueStore so it syncs across the
//  owner's devices without a SwiftData "settings singleton" — which, lacking a
//  CloudKit unique constraint, could silently duplicate across devices (ADR-0002,
//  ADR-0003). Defaults to 1, which makes "This pay period" == "This month".
//

import Foundation

nonisolated enum Payday {
    static let range = 1...31
    static let defaultValue = 1

    private static let key = "payday"
    private static var store: NSUbiquitousKeyValueStore { .default }

    /// The stored payday, clamped to a valid day-of-month. Returns `defaultValue`
    /// when never set (an unset key reads back as 0 from the KV store).
    static var current: Int {
        get {
            let stored = Int(store.longLong(forKey: key))
            guard range.contains(stored) else { return defaultValue }
            return stored
        }
        set {
            store.set(Int64(min(range.upperBound, max(range.lowerBound, newValue))), forKey: key)
        }
    }
}
