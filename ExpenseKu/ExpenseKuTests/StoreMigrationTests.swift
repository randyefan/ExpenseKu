//
//  StoreMigrationTests.swift
//  ExpenseKuTests
//
//  That a store written by the build already on TestFlight opens with this one and
//  reads back exactly as it was written.
//
//  `Fixtures/PlanV2.store` was written by the V2 code itself (commit 40047c3), through
//  the same schema and migration plan the app opens, and carries the V2 model checksum
//  a real 1.1 install has on disk. It holds one of everything the plan can store: a
//  Fixed item Done by hand, an Auto item that posted itself, an item with no Account,
//  an Envelope, a dormant row, transfer ticks, an adjustment, and an October plan made
//  by carry-over.
//
//  `Fixtures/PlanV3.store` is the V2 fixture opened and written by the V3 code (the
//  commit before V4), with one item Funded and one more expense: what a 1.2 install
//  holds before envelope assignment arrives.
//
//  Every test opens a *copy*: SwiftData migrates in place, and the fixture has to stay
//  a pre-change store for the next run.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class StoreMigrationTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "StoreMigrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func copyOfV2Store() throws -> URL {
        try copyOfStore("PlanV2")
    }

    private func copyOfStore(_ name: String) throws -> URL {
        let bundle = Bundle(for: StoreMigrationTests.self)
        let fixture = try XCTUnwrap(bundle.url(forResource: name, withExtension: "store"),
                                    "Fixtures/\(name).store is missing from the test bundle")
        let url = directory.appending(path: "\(name).store")
        try FileManager.default.copyItem(at: fixture, to: url)
        return url
    }

    /// Opened the way `StoreBootstrap` opens the real store, minus CloudKit.
    @MainActor
    private func open(_ url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: ExpenseKuSchemaV4.self)
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: ExpenseKuMigrationPlan.self,
                                  configurations: [config])
    }

    @MainActor
    private func items(in context: ModelContext, plan: CyclePlan) -> [String: PlanItem] {
        Dictionary(uniqueKeysWithValues: (plan.items ?? []).map { ($0.name, $0) })
    }

    @MainActor
    private func plans(in context: ModelContext) throws -> (september: CyclePlan, october: CyclePlan) {
        let plans = try context.fetch(FetchDescriptor<CyclePlan>(sortBy: [SortDescriptor(\.cycleStart)]))
        XCTAssertEqual(plans.count, 2)
        return (try XCTUnwrap(plans.first), try XCTUnwrap(plans.last))
    }

    /// **The V2 store opens**, and every row it held is still there.
    @MainActor
    func testAV2StoreOpensWithEveryRowIntact() throws {
        let context = ModelContext(try open(try copyOfV2Store()))

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CyclePlan>()), 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 12)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<IncomeLine>()), 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransferLine>()), 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Account>()), 4)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Category>()), 5)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Person>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoryGroup>()), 1)
    }

    /// **Nothing arrives Funded.** The new field reads its default on every row, so
    /// every item shows exactly the state it had before the update.
    @MainActor
    func testEveryItemKeepsTheStateItHadBeforeTheUpdate() throws {
        let context = ModelContext(try open(try copyOfV2Store()))
        let (september, october) = try plans(in: context)

        let all = try context.fetch(FetchDescriptor<PlanItem>())
        XCTAssertTrue(all.allSatisfy { !$0.isFunded })
        XCTAssertTrue(all.allSatisfy { PlanItemState.of($0) != .funded })

        let sep = items(in: context, plan: september)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(sep["Kos"])), .done)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(sep["Cicilan Rumah BNI"])), .autoPosted)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(sep["Kirim buat Ibu"])), .todo)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(sep["Arisan kantor"])), .todo)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(sep["Hidup"])), .envelope)

        let oct = items(in: context, plan: october)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(oct["Kos"])), .todo)
        XCTAssertEqual(DoneCheckState.state(for: try XCTUnwrap(oct["Cicilan Rumah BNI"])), .auto)
    }

    /// The relationships survive the migration, the plan-to-ledger link above all:
    /// losing it would silently un-tick every Done item.
    @MainActor
    func testRelationshipsAndLinksSurvive() throws {
        let context = ModelContext(try open(try copyOfV2Store()))
        let (september, october) = try plans(in: context)
        let sep = items(in: context, plan: september)

        let kos = try XCTUnwrap(sep["Kos"])
        XCTAssertEqual(kos.linkedExpense?.amount, 2_250_000)
        XCTAssertEqual(kos.account?.name, "BCA")
        XCTAssertEqual(kos.category?.group?.name, "Housing & Living")
        XCTAssertEqual(kos.dueDay, 5)

        let cicilan = try XCTUnwrap(sep["Cicilan Rumah BNI"])
        XCTAssertTrue(cicilan.isAuto)
        XCTAssertEqual(cicilan.linkedExpense?.needsReview, true)

        XCTAssertEqual(sep["Kirim buat Ibu"]?.people?.map(\.name), ["Ibu"])
        XCTAssertNil(sep["Arisan kantor"]?.account)

        let hidup = try XCTUnwrap(sep["Hidup"])
        XCTAssertEqual(hidup.kind, .envelope)
        XCTAssertNil(hidup.account)
        XCTAssertEqual(Set((hidup.envelopeCategories ?? []).map(\.name)), ["Makan", "Bensin"])
        XCTAssertTrue(sep["Liburan Saving"]?.isDormant == true)

        let lines = september.transferLines ?? []
        XCTAssertEqual(lines.first { $0.account?.name == "BNI" }?.hasTransferred, true)
        XCTAssertEqual(lines.first { $0.account?.name == "Mandiri" }?.adjustment, -700_000)

        XCTAssertEqual(october.copiedFromCycleStart, september.cycleStart)
        XCTAssertEqual(october.items?.count, 6)
        XCTAssertEqual(october.transferLines?.first?.account?.name, "BCA")
        XCTAssertEqual(october.transferLines?.first?.hasTransferred, true)
    }

    /// The derived figures the owner sees are the ones they saw before the update:
    /// no envelope in this store has an Account, so no transfer line moves.
    @MainActor
    func testTransferLinesReadAsBefore() throws {
        let context = ModelContext(try open(try copyOfV2Store()))
        let (september, _) = try plans(in: context)
        let active = PlanDormancy.split(september.items ?? []).active
        let rows = TransferLines.rows(activeItems: active, lines: september.transferLines ?? [])

        XCTAssertEqual(rows.map(\.accountName), ["BNI", "BCA", "Mandiri"])
        XCTAssertEqual(rows.map(\.planned), [7_706_000, 2_200_000, 1_000_000])
        XCTAssertEqual(rows.map(\.transfer), [7_706_000, 2_200_000, 300_000])
        XCTAssertEqual(TransferLines.sentCount(rows), 1)
    }

    /// Once migrated, the store takes the new field, keeps it, and opens again —
    /// the second launch after an update must not migrate twice or fail.
    @MainActor
    func testTheMigratedStoreKeepsFundedAcrossRelaunches() throws {
        let url = try copyOfV2Store()
        do {
            let context = ModelContext(try open(url))
            let (september, _) = try plans(in: context)
            let kirim = try XCTUnwrap(items(in: context, plan: september)["Kirim buat Ibu"])
            kirim.isFunded = true
            try context.save()
        }

        let context = ModelContext(try open(url))
        let (september, _) = try plans(in: context)
        let kirim = try XCTUnwrap(items(in: context, plan: september)["Kirim buat Ibu"])
        XCTAssertTrue(kirim.isFunded)
        XCTAssertEqual(PlanItemState.of(kirim), .funded)
    }

    // MARK: - V3 → V4

    /// **The V3 store opens**, every row intact, and nothing arrives assigned: every
    /// expense counts by Category exactly as it did before the update.
    @MainActor
    func testAV3StoreOpensWithEveryExpenseCountingByCategory() throws {
        let context = ModelContext(try open(try copyOfStore("PlanV3")))
        let (september, _) = try plans(in: context)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 12)
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        XCTAssertEqual(expenses.count, 4)
        XCTAssertTrue(expenses.allSatisfy { EnvelopeChoice.of($0) == .byCategory })
        XCTAssertTrue(try context.fetch(FetchDescriptor<PlanItem>()).allSatisfy { ($0.assignedExpenses ?? []).isEmpty })

        let sep = items(in: context, plan: september)
        XCTAssertEqual(PlanItemState.of(try XCTUnwrap(sep["Kirim buat Ibu"])), .funded)
        XCTAssertEqual(sep["Kos"]?.linkedExpense?.amount, 2_250_000)
    }

    /// Once migrated, an assignment is written, kept, and the store opens again.
    @MainActor
    func testTheMigratedV3StoreKeepsAnAssignmentAcrossRelaunches() throws {
        let url = try copyOfStore("PlanV3")
        do {
            let context = ModelContext(try open(url))
            let (september, _) = try plans(in: context)
            let hidup = try XCTUnwrap(items(in: context, plan: september)["Hidup"])
            let nasi = try XCTUnwrap(try context.fetch(FetchDescriptor<Expense>()).first { $0.note == "Nasi Padang" })
            EnvelopeChoice.envelope(hidup.persistentModelID).apply(to: nasi, envelopes: [hidup])
            try context.save()
        }

        let context = ModelContext(try open(url))
        let nasi = try XCTUnwrap(try context.fetch(FetchDescriptor<Expense>()).first { $0.note == "Nasi Padang" })
        XCTAssertEqual(nasi.envelope?.name, "Hidup")
        XCTAssertFalse(nasi.isOutsideEnvelopes)
    }
}
