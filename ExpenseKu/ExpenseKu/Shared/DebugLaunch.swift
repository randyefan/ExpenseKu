//
//  DebugLaunch.swift
//  ExpenseKu
//
//  DEBUG-only helpers to seed sample data and deep-link to a starting screen
//  via launch arguments, so the app can be driven to a known state for
//  screenshots/manual QA. Never compiled into release builds.
//

#if DEBUG
import Foundation
import SwiftData

enum DebugLaunch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    static var shouldSeed: Bool { args.contains("-seedSampleData") }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// -startTab expenses|insights|manage
    static var startTab: String? { value(for: "-startTab") }

    /// -startScreen categories|people|accounts|leaderboard|person-detail|category-editor|account-editor
    static var startScreen: String? { value(for: "-startScreen") }

    /// Inserts a small, realistic dataset once, only if the store is empty.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        guard shouldSeed else { return }
        let count = (try? context.fetchCount(FetchDescriptor<Expense>())) ?? 0
        guard count == 0 else { return }

        // A couple carry an explicit color/icon to exercise the customization;
        // Kopi is left "auto" so the name-derived fallback stays covered.
        let makan = Category(name: "Makan", colorHex: AppearancePalette.swatches[1], iconName: "fork.knife")
        let transport = Category(name: "Transport", colorHex: AppearancePalette.swatches[8], iconName: "car.fill")
        let kopi = Category(name: "Kopi")
        [makan, transport, kopi].forEach(context.insert)

        let tarisa = Person(name: "Tarisa")
        let fadil = Person(name: "Fadil")
        let budi = Person(name: "Budi")
        [tarisa, fadil, budi].forEach(context.insert)

        let cash = Account(name: "Cash", colorHex: AppearancePalette.swatches[5], iconName: "banknote.fill")
        let gopay = Account(name: "GoPay", colorHex: AppearancePalette.swatches[7], iconName: "wallet.pass.fill")
        [cash, gopay].forEach(context.insert)

        func day(_ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
            Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)) ?? .now
        }

        // One expense left account-less on purpose, to exercise the "Unassigned" bucket.
        // Aug 2 has two expenses at different times, so the list demonstrates that same-day
        // rows order by the time set on each expense (latest first).
        let expenses = [
            Expense(amount: 120_000, date: day(8, 2, 20, 30), note: "Dinner", category: makan, people: [tarisa, fadil], account: gopay),
            Expense(amount: 25_000, date: day(8, 2, 8, 15), note: "Morning coffee", category: kopi, people: [], account: cash),
            Expense(amount: 45_000, date: day(8, 5, 13, 5), note: "Lunch", category: makan, people: [tarisa], account: cash),
            Expense(amount: 30_000, date: day(8, 6, 18, 40), note: "Grab home", category: transport, people: [], account: gopay),
            Expense(amount: 25_000, date: day(7, 20, 9, 25), note: "Latte", category: kopi, people: [fadil, budi], account: cash),
            Expense(amount: 80_000, date: day(7, 28, 19, 0), note: "Ojek + makan", category: makan, people: [budi]),
        ]
        expenses.forEach(context.insert)
    }
}
#endif
