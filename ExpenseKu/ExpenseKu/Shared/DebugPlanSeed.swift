//
//  DebugPlanSeed.swift
//  ExpenseKu
//
//  DEBUG-only cycle-plan fixtures, so every screen of the Plan lens can be driven to a
//  known state for screenshots and for the idb tap-through. Never compiled into
//  release builds.
//
//  **The numbers are the specification, not decoration.** They are tuned to reconcile
//  exactly the way design/ExpenseKu.pen does, so a wrong total is visible at a glance
//  rather than needing arithmetic:
//
//      income 22.000.000 − cost 20.000.000 = Sisa 2.000.000
//      envelope "Hidup"                    = Rp 226.900 left
//      envelope "Kebutuhan Kos di Jkt"     = Rp 48.300 over
//      Fixed drift (Tagihan Handphone Ibu) = Rp 47.300
//      drift strip                         = 48.300 + 47.300 = Rp 95.600
//      the five transfer lines and the group shares each sum to 20.000.000
//
//  Change one figure here and at least two of those stop adding up, which is the
//  point: the fixture checks the arithmetic as well as exercising the layout.
//

#if DEBUG
import Foundation
import SwiftData

enum DebugPlanSeed {
    /// -seedPlanData normal|payday|auto-landed|overspent|none
    static var variant: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-seedPlanData"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        guard let variant, variant != "none" else { return }
        guard (try? context.fetchCount(FetchDescriptor<CyclePlan>())) == 0 else { return }

        let payday = Payday.current
        let calendar = Calendar.current
        let cycle = PayCycle.containing(.now, payday: payday, calendar: calendar)
        let previous = cycle.previous(payday: payday, calendar: calendar)

        let groups = seedGroups(context)
        let categories = seedCategories(context, groups: groups)
        let accounts = seedAccounts(context)
        let people = seedPeople(context)

        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)

        seedIncome(context, plan: plan, variant: variant)
        let items = seedItems(context, plan: plan, categories: categories,
                              accounts: accounts, people: people, variant: variant)
        seedActuals(context, items: items, categories: categories,
                    accounts: accounts, cycle: cycle, variant: variant)
        seedDormant(context, plan: plan, previousStart: previous.start)
        seedTransfers(context, plan: plan, accounts: accounts, variant: variant)
        seedPreviousPlan(context, start: previous.start, categories: categories, accounts: accounts)

        try? context.save()
    }

    // MARK: - Reference data

    private static func seedGroups(_ context: ModelContext) -> [String: CategoryGroup] {
        let names = ["Fixed Obligations", "Lovely Support", "Housing & Living",
                     "Entertainment & Lifestyle", "Personal Care", "Transportation & Travel"]
        var made: [String: CategoryGroup] = [:]
        for (index, name) in names.enumerated() {
            let group = CategoryGroup(name: name, colorHex: AppearancePalette.swatches[index * 2])
            context.insert(group)
            made[name] = group
        }
        return made
    }

    private static func seedCategories(_ context: ModelContext,
                                       groups: [String: CategoryGroup]) -> [String: Category] {
        let spec: [(String, String)] = [
            ("Cicilan", "Fixed Obligations"), ("Tagihan", "Fixed Obligations"),
            ("Sewa", "Housing & Living"), ("Utilitas", "Housing & Living"),
            ("Makan", "Housing & Living"), ("Galon", "Housing & Living"),
            ("Tisu", "Housing & Living"), ("Sabun", "Housing & Living"),
            ("Transfer", "Lovely Support"),
            ("Hiburan", "Entertainment & Lifestyle"),
            ("Kesehatan", "Personal Care"),
            ("Bensin", "Transportation & Travel"), ("Parkir", "Transportation & Travel"),
            ("E-money", "Transportation & Travel"),
        ]
        var made: [String: Category] = [:]
        for (name, group) in spec {
            // Reuse whatever the ordinary sample seed already created, so the two
            // fixtures never produce two "Makan".
            let existing = existingEntity(Category.self, matching: name, in: context)
            let category = existing ?? Category(name: name)
            if existing == nil { context.insert(category) }
            category.group = groups[group]
            made[name] = category
        }
        return made
    }

    private static func seedAccounts(_ context: ModelContext) -> [String: Account] {
        var made: [String: Account] = [:]
        for name in ["BNI", "CC Danamon", "BCA", "Mandiri", "Cash"] {
            let existing = existingEntity(Account.self, matching: name, in: context)
            let account = existing ?? Account(name: name)
            if existing == nil { context.insert(account) }
            made[name] = account
        }
        return made
    }

    private static func seedPeople(_ context: ModelContext) -> [String: Person] {
        var made: [String: Person] = [:]
        for name in ["Ibu", "Tarisa"] {
            let existing = existingEntity(Person.self, matching: name, in: context)
            let person = existing ?? Person(name: name)
            if existing == nil { context.insert(person) }
            made[name] = person
        }
        return made
    }

    // MARK: - The plan

    private static func seedIncome(_ context: ModelContext, plan: CyclePlan, variant: String) {
        // G1 is payday morning: both lines have landed. Everywhere else only the
        // salary has.
        let allArrived = variant == "payday"
        let lines = [IncomeLine(name: "Gaji Fulltime", amount: 20_000_000, hasArrived: true,
                                createdAt: .now, plan: plan),
                     IncomeLine(name: "Tunjangan", amount: 2_000_000, hasArrived: allArrived,
                                createdAt: .now.addingTimeInterval(1), plan: plan)]
        lines.forEach(context.insert)
    }

    private static func seedItems(
        _ context: ModelContext, plan: CyclePlan, categories: [String: Category],
        accounts: [String: Account], people: [String: Person], variant: String
    ) -> [String: PlanItem] {
        // name, amount, category, account, dueDay, isAuto, people
        let fixed: [(String, Decimal, String, String, Int?, Bool, [String])] = [
            ("Cicilan Rumah BNI", 7_706_000, "Cicilan", "BNI", 20, true, []),
            ("Cicil ke Kartu Kredit", 4_700_000, "Cicilan", "CC Danamon", 25, true, []),
            ("Kos", 2_200_000, "Sewa", "BCA", 5, false, []),
            ("Tarisa Needs", 1_500_000, "Transfer", "Mandiri", nil, false, ["Tarisa"]),
            ("Kirim buat Ibu", 1_000_000, "Transfer", "Mandiri", nil, false, ["Ibu"]),
            ("Bayar parkir motor SQ", 650_000, "Parkir", "Cash", nil, false, []),
            ("Tagihan Handphone Ibu", 326_500, "Tagihan", "Mandiri", nil, false, ["Ibu"]),
            ("Gym membership", 300_000, "Kesehatan", "BCA", 1, true, []),
            ("Listrik Kos", 247_300, "Utilitas", "BCA", nil, false, []),
            ("Netflix", 130_000, "Hiburan", "CC Danamon", 2, true, []),
            ("Apple Service", 59_000, "Hiburan", "CC Danamon", 18, true, []),
            ("Vidio", 49_000, "Hiburan", "CC Danamon", 18, true, []),
        ]

        var made: [String: PlanItem] = [:]
        for (offset, spec) in fixed.enumerated() {
            let (name, amount, category, account, dueDay, isAuto, peopleNames) = spec
            let item = PlanItem(
                name: name,
                // I6 needs the plan to run past its income; inflating the largest line
                // is the least invasive way to get there.
                amount: variant == "overspent" && name == "Cicilan Rumah BNI" ? 21_186_000 : amount,
                kind: .fixed,
                dueDay: dueDay,
                isAuto: isAuto,
                carriedOver: true,
                createdAt: .now.addingTimeInterval(Double(offset)),
                plan: plan,
                category: categories[category],
                account: accounts[account],
                people: peopleNames.compactMap { people[$0] }
            )
            context.insert(item)
            made[name] = item
        }

        let envelopes: [(String, Decimal, [String])] = [
            ("Hidup (Makan, bensin, emoney saldo)", 938_300, ["Makan", "Bensin", "E-money"]),
            ("Kebutuhan Kos di Jkt (Tisu, sabun, galon)", 193_900, ["Tisu", "Sabun", "Galon"]),
        ]
        for (offset, spec) in envelopes.enumerated() {
            let (name, amount, categoryNames) = spec
            let item = PlanItem(
                name: name, amount: amount, kind: .envelope,
                carriedOver: true,
                createdAt: .now.addingTimeInterval(Double(100 + offset)),
                plan: plan,
                envelopeCategories: categoryNames.compactMap { categories[$0] }
            )
            context.insert(item)
            made[name] = item
        }
        return made
    }

    /// The expenses that make the envelopes fill and the drift strip appear.
    private static func seedActuals(
        _ context: ModelContext, items: [String: PlanItem], categories: [String: Category],
        accounts: [String: Account], cycle: PayCycle, variant: String
    ) {
        // A fresh plan on payday morning has nothing against it yet (G1).
        guard variant != "payday" else { return }

        let day = Calendar.current.date(byAdding: .day, value: 3, to: cycle.start) ?? cycle.start

        // Hidup: 711.400 spent of 938.300 → Rp 226.900 left.
        for (category, amount) in [("Makan", Decimal(420_000)), ("Bensin", 191_400), ("E-money", 100_000)] {
            context.insert(Expense(amount: amount, date: day, note: "",
                                   category: categories[category], account: accounts["Cash"]))
        }
        // Kebutuhan Kos di Jkt: 242.200 of 193.900 → Rp 48.300 over.
        for (category, amount) in [("Tisu", Decimal(92_200)), ("Sabun", 80_000), ("Galon", 70_000)] {
            context.insert(Expense(amount: amount, date: day, note: "",
                                   category: categories[category], account: accounts["Cash"]))
        }

        // One Fixed item completed above its plan: 373.800 against 326.500 → +47.300.
        // With the envelope's 48.300 that is the drift strip's Rp 95.600.
        if let item = items["Tagihan Handphone Ibu"] {
            context.insert(Expense(amount: 373_800, date: day, note: item.name,
                                   category: item.category, people: item.people ?? [],
                                   account: item.account, planItem: item))
        }

        // G2: five Auto items that posted themselves while the owner was away, one of
        // them at a figure the plan never had.
        if variant == "auto-landed" {
            let posted: [(String, Decimal)] = [
                ("Cicilan Rumah BNI", 7_706_000), ("Cicil ke Kartu Kredit", 6_751_000),
                ("Netflix", 130_000), ("Apple Service", 59_000), ("Vidio", 49_000),
            ]
            for (name, amount) in posted {
                guard let item = items[name] else { continue }
                context.insert(Expense(amount: amount, date: day, note: item.name,
                                       category: item.category, account: item.account,
                                       planItem: item, needsReview: true))
            }
        }
    }

    /// The rows the spreadsheet keeps as reminders and never uses: 11 of them by
    /// September, which on a phone is the whole screen (PRD §7.2).
    private static func seedDormant(_ context: ModelContext, plan: CyclePlan, previousStart: Date) {
        let names = ["Liburan Saving", "New year occasion", "THR fara-eja-tarisa",
                     "Traktir Bude Jogja Bukber", "Service motor", "Beli kado",
                     "Kasih farah uang liburan", "Dana darurat", "Qurban",
                     "Zakat fitrah", "Perpanjang STNK"]
        for (offset, name) in names.enumerated() {
            context.insert(PlanItem(
                name: name, amount: 0, kind: .fixed,
                lastUsedCycleStart: previousStart, carriedOver: true,
                createdAt: .now.addingTimeInterval(Double(200 + offset)), plan: plan
            ))
        }
    }

    private static func seedTransfers(_ context: ModelContext, plan: CyclePlan,
                                      accounts: [String: Account], variant: String) {
        guard variant != "payday" else { return }
        context.insert(TransferLine(account: accounts["BNI"], hasTransferred: true, plan: plan))
        context.insert(TransferLine(account: accounts["CC Danamon"], hasTransferred: true, plan: plan))
        // The adjustment case: money already sitting in the account, so transfer less.
        context.insert(TransferLine(account: accounts["Mandiri"], adjustment: -700_000, plan: plan))
    }

    /// One earlier plan, so F1's "was Rp … in <month>" hint has something to say and
    /// the ‹ arrow has somewhere to go.
    private static func seedPreviousPlan(_ context: ModelContext, start: Date,
                                         categories: [String: Category],
                                         accounts: [String: Account]) {
        let plan = CyclePlan(cycleStart: start)
        context.insert(plan)
        context.insert(IncomeLine(name: "Gaji Fulltime", amount: 20_000_000,
                                  hasArrived: true, plan: plan))

        for (name, planned, actual) in [("Cicil ke Kartu Kredit", Decimal(4_700_000), Decimal(6_751_000)),
                                        ("Tagihan Handphone Ibu", 280_000, 407_500)] {
            let item = PlanItem(name: name, amount: planned, plan: plan,
                                category: categories["Cicilan"], account: accounts["CC Danamon"])
            context.insert(item)
            context.insert(Expense(amount: actual, date: start, note: name,
                                   category: item.category, account: item.account, planItem: item))
        }
    }
}
#endif
