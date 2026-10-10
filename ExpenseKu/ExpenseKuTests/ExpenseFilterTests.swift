//
//  ExpenseFilterTests.swift
//  ExpenseKuTests
//
//  docs/prd/expense-filter.md, one test per rule, on the PRD's own sample (§11): payday 31,
//  today Thu 6 August 2026; only August's plan exists, with three Fixed rows and the Hidup
//  envelope claiming Makan.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class ExpenseFilterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 31

    private func date(_ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: h)) ?? .distantPast
    }

    private var august: PayCycle { PayCycle.containing(date(8, 6), payday: payday, calendar: calendar) }

    private struct Sample {
        let plans: [CyclePlan]
        let expenses: [Expense]
        let categories: [String: Category]
        let groups: [String: CategoryGroup]
        let accounts: [String: Account]
        let people: [String: Person]
        let catalog: FilterCatalog

        func id(_ category: String) -> FilterChoice { .entity(categories[category]!.persistentModelID) }
        func group(_ name: String) -> FilterChoice { .entity(groups[name]!.persistentModelID) }
        func account(_ name: String) -> FilterChoice { .entity(accounts[name]!.persistentModelID) }
        func person(_ name: String) -> FilterChoice { .entity(people[name]!.persistentModelID) }
    }

    @MainActor
    private func sample(_ context: ModelContext) throws -> Sample {
        let housing = CategoryGroup(name: "Housing & Living")
        let fixed = CategoryGroup(name: "Fixed Obligations")
        let fun = CategoryGroup(name: "Entertainment & Lifestyle")
        let travel = CategoryGroup(name: "Transportation & Travel")
        [housing, fixed, fun, travel].forEach(context.insert)

        let kos = Category(name: "Kos", group: housing)
        let internet = Category(name: "Internet", group: housing)
        let makan = Category(name: "Makan", group: housing)
        let cicilan = Category(name: "Cicilan", group: fixed)
        let kopi = Category(name: "Kopi", group: fun)
        let transport = Category(name: "Transport", group: travel)
        [kos, internet, makan, cicilan, kopi, transport].forEach(context.insert)

        let bca = Account(name: "BCA")
        let bni = Account(name: "BNI")
        let gopay = Account(name: "GoPay")
        let cash = Account(name: "Cash")
        [bca, bni, gopay, cash].forEach(context.insert)

        let fadil = Person(name: "Fadil")
        let tarisa = Person(name: "Tarisa")
        [fadil, tarisa].forEach(context.insert)

        let plan = CyclePlan(cycleStart: august.start)
        context.insert(plan)
        var expenses: [Expense] = []
        for (name, amount, category, account) in [("Kos", Decimal(2_500_000), kos, bca),
                                                  ("Cicilan Rumah", Decimal(1_500_000), cicilan, bni),
                                                  ("IndiHome", Decimal(350_000), internet, bca)] {
            let item = PlanItem(name: name, amount: amount, plan: plan, category: category, account: account)
            context.insert(item)
            expenses.append(Expense(amount: amount, date: date(7, 31, 9), note: name, category: category,
                                    account: account, planItem: item))
        }
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: plan, envelopeCategories: [makan]))
        expenses += [
            Expense(amount: 60_000, date: date(7, 12), note: "Lunch", category: makan, account: cash),
            Expense(amount: 55_000, date: date(7, 20), note: "Dinner", category: makan, people: [fadil], account: gopay),
            Expense(amount: 40_000, date: date(7, 25), note: "Iced latte", category: kopi, account: gopay),
            Expense(amount: 25_000, date: date(8, 2, 8), note: "Morning coffee", category: kopi, account: cash),
            Expense(amount: 120_000, date: date(8, 2, 20), note: "Dinner", category: makan, people: [fadil], account: gopay),
            Expense(amount: 45_000, date: date(8, 5, 13), note: "Lunch", category: makan, people: [tarisa], account: cash),
            Expense(amount: 30_000, date: date(8, 6, 18), note: "Grab home", category: transport, account: gopay),
        ]
        expenses.forEach(context.insert)
        try context.save()

        let categories = [kos, internet, makan, cicilan, kopi, transport]
        let groups = [housing, fixed, fun, travel]
        let accounts = [bca, bni, gopay, cash]
        let people = [fadil, tarisa]
        return Sample(
            plans: [plan],
            expenses: expenses,
            categories: Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) }),
            groups: Dictionary(uniqueKeysWithValues: groups.map { ($0.name, $0) }),
            accounts: Dictionary(uniqueKeysWithValues: accounts.map { ($0.name, $0) }),
            people: Dictionary(uniqueKeysWithValues: people.map { ($0.name, $0) }),
            catalog: FilterCatalog(categories: categories, groups: groups, accounts: accounts, people: people)
        )
    }

    private func origins(_ sample: Sample) -> PlanOrigins {
        PlanOrigins(plans: sample.plans, payday: payday, calendar: calendar)
    }

    private func augustExpenses(_ sample: Sample) -> [Expense] {
        CycleContents(cycle: august, allExpenses: sample.expenses, calendar: calendar).expenses
    }

    private func filter(_ picks: (FilterChoice, FilterDimension)...) -> ExpenseFilter {
        var filter = ExpenseFilter()
        for (choice, dimension) in picks { filter.toggle(choice, in: dimension) }
        return filter
    }

    private func total(_ expenses: [Expense]) -> Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    // MARK: - §4.1 Dimensions and matching

    @MainActor
    func testSeveralValuesInOneDimensionMatchAnyOfThem() throws {
        let s = try sample(try makeInMemoryContext())
        let shown = filter((s.id("Makan"), .category), (s.id("Kopi"), .category)).expenses(augustExpenses(s))
        XCTAssertEqual(total(shown), 190_000)
    }

    @MainActor
    func testSeveralPeopleMatchAnyOfThem() throws {
        let s = try sample(try makeInMemoryContext())
        let shown = filter((s.person("Fadil"), .person), (s.person("Tarisa"), .person)).expenses(augustExpenses(s))
        XCTAssertEqual(shown.map(\.note).sorted(), ["Dinner", "Lunch"])
        XCTAssertEqual(total(shown), 165_000)
    }

    @MainActor
    func testDimensionsCombineWithAnd() throws {
        let s = try sample(try makeInMemoryContext())
        let makanGoPay = filter((s.id("Makan"), .category), (s.account("GoPay"), .account))
        let makanBNI = filter((s.id("Makan"), .category), (s.account("BNI"), .account))
        XCTAssertEqual(total(makanGoPay.expenses(augustExpenses(s))), 120_000)
        XCTAssertTrue(makanBNI.expenses(augustExpenses(s)).isEmpty)
    }

    @MainActor
    func testANewFilterIsAllAndNarrowsNothing() throws {
        let s = try sample(try makeInMemoryContext())
        let none = ExpenseFilter()
        XCTAssertTrue(none.isEmpty)
        XCTAssertEqual(none.expenses(augustExpenses(s)).count, 7)
    }

    @MainActor
    func testTogglingTheLastValueOffReturnsTheDimensionToAll() throws {
        let s = try sample(try makeInMemoryContext())
        var f = filter((s.id("Makan"), .category))
        f.toggle(s.id("Makan"), in: .category)
        XCTAssertTrue(f.isEmpty)
        XCTAssertEqual(f, ExpenseFilter())
    }

    @MainActor
    func testGroupIsItsOwnDimensionAndAndsWithCategory() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.group("Housing & Living"), .group), (s.id("Kopi"), .category), (s.id("Kos"), .category))
        XCTAssertEqual(f.expenses(augustExpenses(s)).map(\.note), ["Kos"])
    }

    @MainActor
    func testEveryDimensionMatchesItsEmptyValue() throws {
        let context = try makeInMemoryContext()
        let ungrouped = Category(name: "Lain-lain")
        context.insert(ungrouped)
        let bare = Expense(amount: 10_000, date: date(8, 3))
        let ungroupedRow = Expense(amount: 20_000, date: date(8, 3), category: ungrouped)
        [bare, ungroupedRow].forEach(context.insert)
        try context.save()

        XCTAssertTrue(filter((.none, .category)).admits(bare))
        XCTAssertFalse(filter((.none, .category)).admits(ungroupedRow))
        XCTAssertTrue(filter((.none, .group)).admits(bare))
        XCTAssertTrue(filter((.none, .group)).admits(ungroupedRow))
        XCTAssertTrue(filter((.none, .account)).admits(bare))
        XCTAssertTrue(filter((.none, .person)).admits(bare))
    }

    @MainActor
    func testThePlanFilterAndsWithThisOne() throws {
        let s = try sample(try makeInMemoryContext())
        let filtered = filter((s.id("Makan"), .category), (s.id("Kopi"), .category)).expenses(augustExpenses(s))
        let outside = origins(s).expenses(filtered, in: august, matching: .outsidePlan)
        XCTAssertEqual(outside.map(\.note), ["Morning coffee"])
    }

    @MainActor
    func testADeletedEntityDropsOutOfTheFilter() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.account("BNI"), .account), (s.id("Makan"), .category))
        let withoutBNI = FilterCatalog(
            categories: Array(s.categories.values), groups: Array(s.groups.values),
            accounts: s.accounts.values.filter { $0.name != "BNI" }, people: Array(s.people.values)
        )
        let pruned = withoutBNI.pruning(f)
        XCTAssertEqual(pruned.activeDimensions, [.category])
        XCTAssertEqual(total(pruned.expenses(augustExpenses(s))), 165_000)
    }

    // MARK: - §4.3 The sheet

    @MainActor
    func testChecklistsAreAlphabeticalWithTheEmptyValueLast() throws {
        let s = try sample(try makeInMemoryContext())
        XCTAssertEqual(s.catalog.options(for: .category).map(\.name),
                       ["Cicilan", "Internet", "Kopi", "Kos", "Makan", "Transport", "Uncategorized"])
        XCTAssertEqual(s.catalog.options(for: .group).last?.name, "No group")
        XCTAssertEqual(s.catalog.options(for: .account).map(\.name), ["BCA", "BNI", "Cash", "GoPay", "Unassigned"])
        XCTAssertEqual(s.catalog.options(for: .person).map(\.name), ["Fadil", "Tarisa", "No one"])
    }

    @MainActor
    func testARowSummarisesItsChoicesInChecklistOrder() throws {
        let s = try sample(try makeInMemoryContext())
        XCTAssertEqual(s.catalog.summary(of: ExpenseFilter(), in: .category), "All")
        XCTAssertEqual(s.catalog.summary(of: filter((s.id("Makan"), .category)), in: .category), "Makan")
        XCTAssertEqual(s.catalog.summary(of: filter((s.id("Makan"), .category), (s.id("Kopi"), .category)),
                                         in: .category), "Kopi, Makan")
        let four = filter((s.id("Makan"), .category), (s.id("Kopi"), .category),
                          (s.id("Kos"), .category), (.none, .category))
        XCTAssertEqual(s.catalog.summary(of: four, in: .category), "Kopi, Kos +2")
    }

    // MARK: - §4.4 The pill and the badge

    @MainActor
    func testThePillNamesTheDimensionWhenOnlyOneIsOn() throws {
        let s = try sample(try makeInMemoryContext())
        let people = filter((s.person("Fadil"), .person), (s.person("Tarisa"), .person))
        XCTAssertEqual(s.catalog.pillText(for: people), "Person · Fadil, Tarisa")
    }

    @MainActor
    func testThePillJoinsValuesInDimensionOrderWhenSeveralAreOn() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.account("BNI"), .account), (s.id("Makan"), .category))
        XCTAssertEqual(s.catalog.pillText(for: f), "Makan · BNI")
        XCTAssertEqual(f.activeDimensions.count, 2)
    }

    // MARK: - §4.8 The plan filter in the sheet

    @MainActor
    func testTheBadgeCountsThePlanFilterAlongsideTheDimensions() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.id("Makan"), .category), (s.account("Cash"), .account))
        XCTAssertEqual(f.activeCount(planFilter: nil), 2)
        XCTAssertEqual(f.activeCount(planFilter: .outsidePlan), 3)
        XCTAssertEqual(ExpenseFilter().activeCount(planFilter: .fromPlan), 1)
    }

    // MARK: - §4.5 The SPENDING hero and the split

    @MainActor
    func testTheHeroIsTheFilteredTotalOfTheWhole() throws {
        let s = try sample(try makeInMemoryContext())
        let whole = CycleContents(cycle: august, allExpenses: s.expenses, calendar: calendar)
        let f = filter((s.id("Makan"), .category), (s.id("Kopi"), .category))
        let filtered = CycleContents(cycle: august, allExpenses: f.expenses(whole.expenses), calendar: calendar)
        XCTAssertEqual(filtered.total, 190_000)
        XCTAssertEqual(f.ofTotal(whole.total), 4_570_000)
        XCTAssertNil(ExpenseFilter().ofTotal(whole.total))
    }

    @MainActor
    func testTheSplitDescribesTheFilteredSet() throws {
        let s = try sample(try makeInMemoryContext())
        let shown = filter((s.id("Makan"), .category), (s.id("Kopi"), .category)).expenses(augustExpenses(s))
        XCTAssertEqual(origins(s).split(shown, in: august), SpendingSplit(outsidePlan: 25_000, fromPlan: 165_000))
        let gopay = filter((s.account("GoPay"), .account)).expenses(augustExpenses(s))
        XCTAssertEqual(origins(s).split(gopay, in: august), SpendingSplit(outsidePlan: 30_000, fromPlan: 120_000))
    }

    @MainActor
    func testAFilteredSetWithNothingFromThePlanDrawsNoSplit() throws {
        let s = try sample(try makeInMemoryContext())
        let shown = filter((s.id("Makan"), .category), (s.account("BNI"), .account)).expenses(augustExpenses(s))
        XCTAssertFalse(PlanFilter.showsLegend(for: origins(s).split(shown, in: august), filter: nil))
    }

    // MARK: - §4.6 Empty

    func testAnEmptiedListNamesTheFiltersAndOffersToClearThem() {
        var f = ExpenseFilter()
        f.toggle(.none, in: .account)
        let notice = EmptyNotice.cycle(filter: f, filteredIsEmpty: true, planFilter: .outsidePlan,
                                       span: "31/07/2026 ~ 30/08/2026")
        XCTAssertEqual(notice, EmptyNotice(title: "Nothing matches these filters",
                                           detail: "No expenses in 31/07/2026 ~ 30/08/2026 match these filters.",
                                           offersClearFilters: true))
    }

    func testThePlanFiltersMessageWinsWhenItsHalfIsWhatIsEmpty() {
        var f = ExpenseFilter()
        f.toggle(.none, in: .account)
        let notice = EmptyNotice.cycle(filter: f, filteredIsEmpty: false, planFilter: .outsidePlan, span: "x")
        XCTAssertEqual(notice?.title, "Nothing outside the plan")
        XCTAssertEqual(notice?.offersClearFilters, false)
        XCTAssertNil(EmptyNotice.cycle(filter: ExpenseFilter(), filteredIsEmpty: true, planFilter: nil, span: "x"))
    }

    func testAnEmptyMonthDayNamesTheFilters() {
        var f = ExpenseFilter()
        f.toggle(.none, in: .person)
        let notice = EmptyNotice.day(filter: f, filteredDayIsEmpty: true, planFilter: nil, dayPhrase: "on Sun, 2 August")
        XCTAssertEqual(notice?.title, "Nothing matches on Sun, 2 August")
        XCTAssertEqual(notice?.offersClearFilters, true)
    }

    func testAnEmptyInsightsChartSaysNothingMatches() {
        var f = ExpenseFilter()
        f.toggle(.none, in: .person)
        XCTAssertEqual(EmptyNotice.chart(filter: f, filteredIsEmpty: true, planFilter: .fromPlan),
                       "Nothing matches these filters in this period.")
        XCTAssertEqual(EmptyNotice.chart(filter: f, filteredIsEmpty: false, planFilter: .fromPlan),
                       "Nothing from the plan in this period.")
    }

    // MARK: - §5 Expenses tab

    @MainActor
    func testDayHeadersAddUpVisibleRowsAndEmptyDaysDisappear() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.id("Makan"), .category), (s.id("Kopi"), .category))
        let contents = CycleContents(cycle: august, allExpenses: f.expenses(augustExpenses(s)), calendar: calendar)
        XCTAssertEqual(contents.dayGroups.map(\.total), [45_000, 145_000])
        XCTAssertNil(contents.group(for: calendar.startOfDay(for: date(7, 31))))
    }

    // MARK: - §6 Insights

    @MainActor
    func testInsightsBreakdownsRankOnlyMatchingExpenses() throws {
        let s = try sample(try makeInMemoryContext())
        let shown = filter((s.person("Fadil"), .person), (s.person("Tarisa"), .person)).expenses(augustExpenses(s))
        XCTAssertEqual(SpendSummary.byCategory(from: shown).map(\.categoryName), ["Makan"])
        XCTAssertEqual(SpendSummary.byAccount(from: shown).map(\.total), [120_000, 45_000])
    }

    @MainActor
    func testSpendOverTimeDrawsEachCyclesMatchingSpend() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.person("Fadil"), .person), (s.person("Tarisa"), .person))
        let window = PayPeriodChoices.trendWindow(count: 12, selected: august, now: date(8, 6, 21),
                                                  payday: payday, calendar: calendar)
        let bars = SpendSummary.byPayPeriod(from: f.expenses(s.expenses), window: window, calendar: calendar)
        XCTAssertEqual(bars.map(\.total), [55_000, 165_000])
    }

    // MARK: - §6.1 The drill-in

    @MainActor
    func testTheDrillInCarriesTheFilterAndItsShareIsOverTheFilteredWindow() throws {
        let s = try sample(try makeInMemoryContext())
        let gopay = SpendSubject.account(s.accounts["GoPay"]!.persistentModelID)
        let carried = filter((s.person("Fadil"), .person), (s.person("Tarisa"), .person)).dropping(gopay.dimension)
        let detail = SpendEntityDetail(
            expenses: s.expenses, subject: gopay, narrowing: nil,
            dateRange: august.start...date(8, 6, 21), planFilter: nil, filter: carried, origins: origins(s)
        )
        XCTAssertEqual(detail.total, 120_000)
        XCTAssertEqual(detail.share ?? 0, 120.0 / 165.0, accuracy: 0.0001)
        XCTAssertEqual(detail.split, SpendingSplit(outsidePlan: 0, fromPlan: 120_000))
        XCTAssertEqual(detail.breakdown.map(\.name), ["Makan"])
    }

    @MainActor
    func testTheDrillInDropsItsSubjectsOwnDimension() throws {
        let s = try sample(try makeInMemoryContext())
        let f = filter((s.id("Makan"), .category), (s.account("GoPay"), .account))
        XCTAssertEqual(f.dropping(SpendSubject.uncategorized.dimension).activeDimensions, [.account])
        XCTAssertEqual(f.dropping(SpendSubject.unassigned.dimension).activeDimensions, [.category])
    }

    @MainActor
    func testNarrowingWorksInsideTheFilteredSet() throws {
        let s = try sample(try makeInMemoryContext())
        let makan = SpendSubject.category(s.categories["Makan"]!.persistentModelID)
        let cash = SpendSubject.account(s.accounts["Cash"]!.persistentModelID)
        let detail = SpendEntityDetail(
            expenses: s.expenses, subject: makan, narrowing: cash,
            dateRange: august.start...date(8, 6, 21), planFilter: nil,
            filter: filter((s.person("Fadil"), .person)), origins: origins(s)
        )
        XCTAssertTrue(detail.listed.isEmpty)
        XCTAssertEqual(detail.breakdown.map(\.name), ["GoPay"])
    }
}
