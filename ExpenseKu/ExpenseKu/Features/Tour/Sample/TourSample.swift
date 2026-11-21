//
//  TourSample.swift
//  ExpenseKu
//
//  The tour's own store (welcome-tour.md §5): People, Accounts, Categories, two cycles of
//  expenses and this cycle's plan, built relative to today with payday 25. Every model goes
//  into this in-memory container alone, so nothing the tour does reaches the user's data.
//
//  A chapter started fresh rebuilds the store as it stands at that chapter's start, so
//  chapters 2–4 already hold chapter 1's two expenses.
//

import Foundation
import SwiftData

@MainActor
final class TourSample {
    static let payday = 25

    let container: ModelContainer
    let calendar: Calendar
    let today: Date
    let cycle: PayCycle
    let lastCycle: PayCycle
    private(set) var recordedExpense: Expense?

    private let context: ModelContext
    private var categories: [String: Category] = [:]
    private var accounts: [String: Account] = [:]
    private var people: [String: Person] = [:]
    private var me: Person?

    init(startingAt chapter: TourChapter, today: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        self.today = today
        cycle = PayCycle.containing(today, payday: Self.payday, calendar: calendar)
        lastCycle = cycle.previous(payday: Self.payday, calendar: calendar)

        let schema = Schema(versionedSchema: ExpenseKuSchemaV9.self)
        let configuration = ModelConfiguration("TourSample", schema: schema,
                                               isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("The tour's in-memory sample store could not open: \(error)")
        }
        context = container.mainContext

        insertCatalog()
        insertLastCycle()
        insertThisCycle()
        if chapter > .record {
            addChapterOneExpenses()
        }
        try? context.save()
    }

    var lastCycleName: String {
        lastCycle.lastDay(calendar: calendar).formatted(.dateTime.month(.wide).locale(AppLocalization.locale))
    }

    func adopt(recorded expense: Expense) {
        recordedExpense = expense
    }

    private func insertCatalog() {
        let catalog: [(String, Int, String)] = [
            ("Makan", 1, "fork.knife"), ("Transport", 8, "car.fill"), ("Belanja", 3, "cart.fill"),
            ("Hiburan", 6, "film.fill"), ("Kos", 4, "house.fill"),
        ]
        for (name, swatch, icon) in catalog {
            let category = Category(name: name, colorHex: AppearancePalette.swatches[swatch], iconName: icon)
            context.insert(category)
            categories[name] = category
        }

        let jago = Account(name: "Jago")
        jago.brandID = "jago"
        let mandiri = Account(name: "Mandiri")
        mandiri.brandID = "mandiri"
        let cash = Account(name: "Cash", colorHex: AppearancePalette.swatches[5], iconName: "banknote.fill")
        for account in [jago, mandiri, cash] {
            context.insert(account)
            accounts[account.name] = account
        }

        let owner = Person(name: Person.meName, isMe: true)
        context.insert(owner)
        me = owner
        for name in ["Ibu", "Rina"] {
            let person = Person(name: name)
            context.insert(person)
            people[name] = person
        }
    }

    private func insertThisCycle() {
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        context.insert(IncomeLine(name: "Gaji", amount: 8_000_000, hasArrived: true, plan: plan))
        let kos = PlanItem(name: "Kos", amount: 2_200_000, kind: .fixed, dueDay: Self.payday,
                           createdAt: cycle.start, plan: plan, category: categories["Kos"],
                           account: accounts["Mandiri"])
        kos.isFunded = true
        context.insert(kos)
        let harian = PlanItem(name: "Harian", amount: 1_800_000, kind: .envelope,
                              createdAt: cycle.start.addingTimeInterval(1), plan: plan,
                              account: accounts["Jago"],
                              envelopeCategories: [categories["Makan"], categories["Transport"]].compactMap { $0 })
        harian.isFunded = true
        context.insert(harian)

        insert(2_200_000, "Kos", "Kos", nil, "Mandiri", at: cycle.start.addingTimeInterval(9 * 3600), planItem: kos)
        let spending: [(Decimal, String, String, String?, String, Int, Int)] = [
            (38_000, "Nasi padang", "Makan", "Ibu", "Jago", 0, 12),
            (28_000, "Kopi susu", "Makan", "Rina", "Cash", 1, 15),
            (24_500, "Gojek ke kantor", "Transport", nil, "Jago", 1, 8),
            (186_400, "Indomaret", "Belanja", "Ibu", "Mandiri", 2, 19),
            (52_000, "Bakso", "Makan", "Ibu", "Jago", 3, 13),
            (75_000, "Bioskop", "Hiburan", "Rina", "Jago", 5, 20),
            (120_000, "Makan malam keluarga", "Makan", "Ibu", "Mandiri", 6, 19),
            (18_000, "KRL", "Transport", nil, "Cash", 8, 7),
            (64_900, "Sabun, tisu", "Belanja", nil, "Mandiri", 9, 18),
            (45_500, "Ayam geprek", "Makan", "Rina", "Jago", 11, 12),
            (150_000, "Bensin", "Transport", nil, "Cash", 12, 9),
            (96_000, "Sate", "Makan", "Ibu", "Jago", 13, 20),
        ]
        for (amount, note, category, person, account, daysAgo, hour) in spending {
            insert(amount, note, category, person, account, at: thisCycleDate(daysAgo: daysAgo, hour: hour))
        }
    }

    private func insertLastCycle() {
        let spending: [(Decimal, String, String, String?, String?, Int, Int)] = [
            (50_000, "Pulsa", "Belanja", nil, "Jago", 7, 10),
            (36_500, "Grab", "Transport", nil, "Jago", 11, 8),
            (58_000, "Martabak", "Makan", "Rina", "Cash", 16, 20),
            (100_000, "Bioskop", "Hiburan", "Rina", "Jago", 19, 19),
            (212_700, "Superindo", "Belanja", "Ibu", "Mandiri", 23, 17),
            (150_000, "Bensin", "Transport", nil, "Cash", 25, 9),
            (64_000, "Mie ayam", "Makan", "Ibu", "Jago", 27, 12),
        ]
        insert(2_200_000, "Kos", "Kos", nil, "Mandiri", at: lastCycleDate(day: 0, hour: 9), planItem: nil)
            .people = []
        for (amount, note, category, person, account, day, hour) in spending {
            insert(amount, note, category, person, account, at: lastCycleDate(day: day, hour: hour))
        }
    }

    private func addChapterOneExpenses() {
        let recorded = insert(45_000, "", "Makan", "Ibu", "Jago", at: today.addingTimeInterval(-2 * 60))
        recorded.people = [me, people["Ibu"]].compactMap { $0 }
        recordedExpense = recorded
        let receipt = insert(32_000, "Kopi susu", "Makan", nil, "Jago", at: today.addingTimeInterval(-60))
        receipt.needsReview = true
        receipt.receiptImage = TourReceipt.imageData()
    }

    @discardableResult
    private func insert(_ amount: Decimal, _ note: String, _ category: String, _ person: String?,
                        _ account: String?, at date: Date, planItem: PlanItem? = nil) -> Expense {
        let tagged: [Person]
        switch (person, planItem) {
        case (_, .some): tagged = []
        case (.none, .none): tagged = me.map { [$0] } ?? []
        case (.some(let name), .none): tagged = people[name].map { [$0] } ?? []
        }
        let expense = Expense(amount: amount, date: date, note: note, category: categories[category],
                              people: tagged, account: account.flatMap { accounts[$0] }, planItem: planItem)
        context.insert(expense)
        return expense
    }

    private func thisCycleDate(daysAgo: Int, hour: Int) -> Date {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: today)) ?? today
        let clamped = max(day, calendar.date(byAdding: .day, value: 1, to: cycle.start) ?? cycle.start)
        let atHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: clamped) ?? clamped
        return daysAgo == 0 ? min(atHour, today.addingTimeInterval(-30 * 60)) : atHour
    }

    private func lastCycleDate(day: Int, hour: Int) -> Date {
        let date = calendar.date(byAdding: .day, value: day, to: lastCycle.start) ?? lastCycle.start
        let atHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        return min(atHour, lastCycle.end.addingTimeInterval(-3600))
    }
}
