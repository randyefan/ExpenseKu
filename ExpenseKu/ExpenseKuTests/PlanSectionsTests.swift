//
//  PlanSectionsTests.swift
//  ExpenseKuTests
//
//  Ordering and grouping the plan's items (docs/prd/plan-sort.md §4). The fixture is
//  flow M's sample plan — twelve items, payday 25, the cycle 25 Oct → 24 Nov 2026 —
//  so each test reads against the frame that draws it.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanSectionsTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private var cycle: PayCycle {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)) ?? .distantPast
        return PayCycle.containing(day, payday: 25, calendar: calendar)
    }

    @MainActor
    private func makeSamplePlan(_ context: ModelContext) throws -> [PlanItem] {
        let obligations = CategoryGroup(name: "Fixed Obligations")
        let support = CategoryGroup(name: "Lovely Support")
        let housing = CategoryGroup(name: "Housing & Living")
        let fun = CategoryGroup(name: "Entertainment & Lifestyle")
        [obligations, support, housing, fun].forEach(context.insert)

        let cicilan = Category(name: "Cicilan", group: obligations)
        let sewa = Category(name: "Sewa", group: obligations)
        let utilitas = Category(name: "Utilitas", group: obligations)
        let transfer = Category(name: "Transfer", group: support)
        let pulsa = Category(name: "Pulsa", group: support)
        let makan = Category(name: "Makan", group: housing)
        let galon = Category(name: "Galon", group: housing)
        let hiburan = Category(name: "Hiburan", group: fun)
        let transport = Category(name: "Transport")
        [cicilan, sewa, utilitas, transfer, pulsa, makan, galon, hiburan, transport].forEach(context.insert)

        let bni = Account(name: "BNI"), danamon = Account(name: "CC Danamon"), bca = Account(name: "BCA")
        let mandiri = Account(name: "Mandiri"), jago = Account(name: "Jago"), cash = Account(name: "Cash")
        [bni, danamon, bca, mandiri, jago, cash].forEach(context.insert)

        let items = [
            PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 5, isAuto: true, category: cicilan, account: bni),
            PlanItem(name: "Cicil ke Kartu Kredit", amount: 4_700_000, dueDay: 20, isAuto: true, category: cicilan, account: danamon),
            PlanItem(name: "Kos", amount: 2_200_000, dueDay: 1, category: sewa, account: bca),
            PlanItem(name: "Kirim buat Ibu", amount: 2_000_000, category: transfer, account: mandiri),
            PlanItem(name: "Tarisa Needs", amount: 1_500_000, category: transfer, account: bca),
            PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago, envelopeCategories: [makan, galon]),
            PlanItem(name: "Bayar parkir motor SQ", amount: 650_000, category: transport, account: cash),
            PlanItem(name: "Tagihan Handphone Ibu", amount: 407_500, dueDay: 25, category: pulsa, account: mandiri),
            PlanItem(name: "Hiburan", amount: 300_000, category: hiburan),
            PlanItem(name: "Listrik Kos", amount: 247_300, dueDay: 28, category: utilitas, account: bca),
            PlanItem(name: "Kebutuhan Kos di Jkt", amount: 193_900, kind: .envelope, envelopeCategories: [galon]),
            PlanItem(name: "Netflix", amount: 130_000, dueDay: 12, isAuto: true, category: hiburan, account: danamon),
        ]
        items.forEach(context.insert)
        named(items, "Cicilan Rumah BNI").isFunded = true
        named(items, "Kirim buat Ibu").isFunded = true
        named(items, "Hidup").isFunded = true
        context.insert(Expense(amount: 2_200_000, planItem: named(items, "Kos")))
        context.insert(Expense(amount: 247_300, planItem: named(items, "Listrik Kos")))
        try context.save()
        return items
    }

    private func named(_ items: [PlanItem], _ name: String) -> PlanItem {
        items.first { $0.name == name } ?? PlanItem()
    }

    private func sections(_ items: [PlanItem], _ sort: PlanSort) -> [PlanSection] {
        PlanSections.sections(items, by: sort, cycle: cycle, calendar: calendar)
    }

    private func names(_ section: PlanSection) -> [String] {
        section.items.map(\.name)
    }

    // MARK: - Flat orders

    /// Amount is the default and must stay exactly today's order (payday-planning §9.1).
    @MainActor
    func testAmountIsTheExistingOrderInOneHeaderlessSection() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        let result = sections(items.shuffled(), .amount)
        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result[0].title)
        XCTAssertEqual(names(result[0]), PlanDormancy.sorted(items).map(\.name))
    }

    /// M4: by where the day falls in the cycle — Due 25 and 28 before Due 1 — then the
    /// undated tail by amount.
    @MainActor
    func testDueDayFollowsTheCycleThenTheUndatedTailByAmount() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        let result = sections(items, .dueDay)
        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result[0].title)
        XCTAssertEqual(names(result[0]), [
            "Tagihan Handphone Ibu", "Listrik Kos", "Kos", "Cicilan Rumah BNI", "Netflix",
            "Cicil ke Kartu Kredit",
            "Kirim buat Ibu", "Tarisa Needs", "Hidup", "Bayar parkir motor SQ", "Hiburan",
            "Kebutuhan Kos di Jkt",
        ])
    }

    /// A due day the cycle cannot reach (a walking payday-31 cycle) sorts with the
    /// undated items rather than at a date outside the cycle.
    @MainActor
    func testAnUnreachableDueDaySortsWithTheUndated() throws {
        let context = try makeInMemoryContext()
        let unreachable = PlanItem(name: "Day 29", amount: 100, dueDay: 29)
        let undated = PlanItem(name: "Undated", amount: 200)
        let dated = PlanItem(name: "Day 5", amount: 50, dueDay: 5)
        [unreachable, undated, dated].forEach(context.insert)
        let day = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)) ?? .distantPast
        let walking = PayCycle.containing(day, payday: 31, calendar: calendar)

        let ordered = PlanSections.byDueDay([unreachable, undated, dated], cycle: walking, calendar: calendar)
        XCTAssertEqual(ordered.map(\.name), ["Day 5", "Undated", "Day 29"])
    }

    /// Name compares the way Finder does: case-insensitively, and "2" before "10".
    @MainActor
    func testNameUsesLocalizedStandardCompare() throws {
        let context = try makeInMemoryContext()
        let items = [PlanItem(name: "item 10", amount: 1), PlanItem(name: "Item 2", amount: 1),
                     PlanItem(name: "apel", amount: 1)]
        items.forEach(context.insert)
        let result = sections(items, .name)
        XCTAssertEqual(names(result[0]), ["apel", "Item 2", "item 10"])
    }

    // MARK: - Grouped orders

    /// M2: one section per Account, largest planned total first, Unassigned last;
    /// inside, due day in cycle.
    @MainActor
    func testAccountGroupsByTotalWithUnassignedLast() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        let result = sections(items, .account)
        XCTAssertEqual(result.map(\.title), [
            "BNI · 1 item", "CC Danamon · 2 items", "BCA · 3 items", "Mandiri · 2 items",
            "Jago · 1 item", "Cash · 1 item", "Unassigned · 2 items",
        ])
        XCTAssertEqual(names(result[1]), ["Netflix", "Cicil ke Kartu Kredit"])
        XCTAssertEqual(names(result[2]), ["Listrik Kos", "Kos", "Tarisa Needs"])
        XCTAssertEqual(names(result[6]), ["Hiburan", "Kebutuhan Kos di Jkt"])
    }

    /// Unassigned stays last however much it holds — it is the absence of an answer.
    @MainActor
    func testUnassignedIsLastEvenWhenLargest() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let items = [PlanItem(name: "Small", amount: 100, account: bca),
                     PlanItem(name: "Big", amount: 9_000_000)]
        items.forEach(context.insert)
        XCTAssertEqual(sections(items, .account).map(\.title), ["BCA · 1 item", "Unassigned · 1 item"])
    }

    /// M3: Group order matches the share table, an Envelope lands in its modal Group,
    /// and an item whose Category has no Group falls into Ungrouped, last.
    @MainActor
    func testGroupMatchesTheShareTable() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        let result = sections(items, .group)
        XCTAssertEqual(result.map(\.title), [
            "Fixed Obligations · 4 items", "Lovely Support · 3 items", "Housing & Living · 2 items",
            "Entertainment & Lifestyle · 2 items", "Ungrouped · 1 item",
        ])
        XCTAssertEqual(names(result[0]), ["Listrik Kos", "Kos", "Cicilan Rumah BNI", "Cicil ke Kartu Kredit"])
        XCTAssertEqual(names(result[2]), ["Hidup", "Kebutuhan Kos di Jkt"])

        let shareOrder = GroupShares.rows(activeItems: items, totalIncome: 1).map(\.groupName)
        XCTAssertEqual(result.compactMap(\.title).map { String($0.prefix { $0 != "·" }).trimmingCharacters(in: .whitespaces) },
                       shareOrder)
    }

    /// M5: Todo → Funded → Done. A covered Auto item is Funded, an Envelope stops at
    /// Funded, and a state with nothing in it gets no section.
    @MainActor
    func testStatusRunsTodoFundedDone() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        let result = sections(items, .status)
        XCTAssertEqual(result.map(\.title), ["Todo · 7 items", "Funded · 3 items", "Done · 2 items"])
        XCTAssertEqual(names(result[1]), ["Cicilan Rumah BNI", "Kirim buat Ibu", "Hidup"])
        XCTAssertEqual(names(result[2]), ["Listrik Kos", "Kos"])

        let todoOnly = items.filter { PlanItemState.of($0) == .todo }
        XCTAssertEqual(sections(todoOnly, .status).map(\.title), ["Todo · 7 items"])
    }

    /// Every order shows every item exactly once.
    @MainActor
    func testEveryOrderKeepsEveryItem() throws {
        let items = try makeSamplePlan(makeInMemoryContext())
        for sort in PlanSort.allCases {
            let shown = sections(items, sort).flatMap(\.items).map(\.persistentModelID)
            XCTAssertEqual(Set(shown), Set(items.map(\.persistentModelID)), "\(sort)")
            XCTAssertEqual(shown.count, items.count, "\(sort)")
        }
    }

    func testNoItemsMeansNoSections() {
        XCTAssertTrue(PlanSections.sections([], by: .account, cycle: cycle, calendar: calendar).isEmpty)
    }
}
