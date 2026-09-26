//
//  FundedStateTests.swift
//  ExpenseKuTests
//
//  The middle state of a plan item: its money is in its Account, not yet paid
//  (PRD §7.6, decisions 24–31).
//
//  The state is derived — Done if linked, else Funded if `isFunded` and an Account,
//  else Todo — and most of these tests are that rule seen from one more side: the
//  control's face, what tapping it offers, the transfer checklist, the notice, carry-
//  over, and what an older build on another device can do to the flag.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class FundedStateTests: XCTestCase {

    // MARK: - The derived rule

    @MainActor
    func testTheStateIsDoneThenFundedThenTodo() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let item = PlanItem(name: "Kirim buat Ibu", amount: 1_000_000, account: mandiri)
        context.insert(item)
        XCTAssertEqual(PlanItemState.of(item), .todo)

        item.isFunded = true
        XCTAssertEqual(PlanItemState.of(item), .funded)

        context.insert(Expense(amount: 1_000_000, planItem: item))
        try context.save()
        XCTAssertEqual(PlanItemState.of(item), .done, "Done wins over Funded")
    }

    /// **No Account, no Funded** (decision 28). The flag alone is not enough.
    @MainActor
    func testAnItemWithNoAccountIsNeverFunded() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Arisan kantor", amount: 200_000)
        context.insert(item)
        item.isFunded = true
        XCTAssertEqual(PlanItemState.of(item), .todo)
    }

    /// Clearing the Account returns the item to Todo without touching the flag, so
    /// no combination of edits can contradict itself.
    @MainActor
    func testClearingTheAccountReturnsToTodoAndKeepsTheFlag() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let item = PlanItem(name: "Kirim buat Ibu", amount: 1_000_000, account: mandiri)
        context.insert(item)
        item.isFunded = true

        item.account = nil
        XCTAssertEqual(PlanItemState.of(item), .todo)
        XCTAssertTrue(item.isFunded)
    }

    // MARK: - The control's faces

    @MainActor
    func testEveryKindHasAFundedFace() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI"), jago = Account(name: "Jago"), mandiri = Account(name: "Mandiri")
        [bni, jago, mandiri].forEach(context.insert)
        let manual = PlanItem(name: "Kirim buat Ibu", amount: 1, account: mandiri)
        let auto = PlanItem(name: "Cicilan Rumah BNI", amount: 1, dueDay: 20, isAuto: true, account: bni)
        let envelope = PlanItem(name: "Hidup", amount: 1, kind: .envelope, account: jago)
        [manual, auto, envelope].forEach(context.insert)

        XCTAssertEqual(DoneCheckState.state(for: manual), .todo)
        XCTAssertEqual(DoneCheckState.state(for: auto), .auto)
        XCTAssertEqual(DoneCheckState.state(for: envelope), .envelope)

        [manual, auto, envelope].forEach { $0.isFunded = true }
        XCTAssertEqual(DoneCheckState.state(for: manual), .funded)
        XCTAssertEqual(DoneCheckState.state(for: auto), .autoFunded)
        XCTAssertEqual(DoneCheckState.state(for: envelope), .envelopeFunded)

        context.insert(Expense(amount: 1, planItem: auto))
        try context.save()
        XCTAssertEqual(DoneCheckState.state(for: auto), .autoPosted,
                       "an Auto item posts whatever its funded state (ADR-0007)")
    }

    // MARK: - What tapping offers (§7.6 table)

    @MainActor
    func testTheMenusMatchTheTable() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA"), bni = Account(name: "BNI"), jago = Account(name: "Jago")
        [bca, bni, jago].forEach(context.insert)
        let manual = PlanItem(name: "Tarisa Needs", amount: 1, account: bca)
        let auto = PlanItem(name: "Cicilan Rumah BNI", amount: 1, dueDay: 20, isAuto: true, account: bni)
        let envelope = PlanItem(name: "Hidup", amount: 1, kind: .envelope, account: jago)
        [manual, auto, envelope].forEach(context.insert)

        XCTAssertEqual(DoneCheckTap.of(manual), .menu([.moved(account: "BCA"), .paid]))
        XCTAssertEqual(DoneCheckTap.of(auto), .menu([.covered(account: "BNI")]))
        XCTAssertEqual(DoneCheckTap.of(envelope), .menu([.moved(account: "Jago")]))

        [manual, auto, envelope].forEach { $0.isFunded = true }
        XCTAssertEqual(DoneCheckTap.of(manual), .menu([.paid, .notMoved]))
        XCTAssertEqual(DoneCheckTap.of(auto), .menu([.notCovered]))
        XCTAssertEqual(DoneCheckTap.of(envelope), .menu([.notMoved]))
    }

    /// Without an Account every control behaves exactly as it did before §7.6: ◯
    /// opens the Done sheet directly, the bolt and the tray are inert (L7).
    @MainActor
    func testWithNoAccountTheControlsBehaveAsBefore() throws {
        let context = try makeInMemoryContext()
        let manual = PlanItem(name: "Arisan kantor", amount: 1)
        let auto = PlanItem(name: "Netflix", amount: 1, dueDay: 2, isAuto: true)
        let envelope = PlanItem(name: "Hidup", amount: 1, kind: .envelope)
        [manual, auto, envelope].forEach(context.insert)
        [manual, auto, envelope].forEach { $0.isFunded = true }

        XCTAssertEqual(DoneCheckTap.of(manual), .confirmDone)
        XCTAssertEqual(DoneCheckTap.of(auto), .none)
        XCTAssertEqual(DoneCheckTap.of(envelope), .none)
    }

    /// A Done item still un-ticks through I4, Account or not.
    @MainActor
    func testADoneItemUnticks() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let withAccount = PlanItem(name: "Kos", amount: 1, account: bca)
        let without = PlanItem(name: "Arisan", amount: 1)
        let auto = PlanItem(name: "Netflix", amount: 1, dueDay: 2, isAuto: true, account: bca)
        [withAccount, without, auto].forEach(context.insert)
        [withAccount, without, auto].forEach { context.insert(Expense(amount: 1, planItem: $0)) }
        try context.save()

        XCTAssertEqual(DoneCheckTap.of(withAccount), .untick)
        XCTAssertEqual(DoneCheckTap.of(without), .untick)
        XCTAssertEqual(DoneCheckTap.of(auto), .untick)
    }

    func testTheMenuEntriesSayWhatTheyDo() {
        XCTAssertEqual(FundMenuEntry.moved(account: "BCA").title, "Moved to BCA")
        XCTAssertEqual(FundMenuEntry.moved(account: "BCA").subtitle, "Money is in the account")
        XCTAssertEqual(FundMenuEntry.paid.title, "Paid…")
        XCTAssertEqual(FundMenuEntry.paid.subtitle, "Log the expense now")
        XCTAssertEqual(FundMenuEntry.notMoved.title, "Not moved yet")
        XCTAssertEqual(FundMenuEntry.notMoved.subtitle, "Back to Todo")
        XCTAssertEqual(FundMenuEntry.covered(account: "BNI").title, "Covered in BNI")
        XCTAssertEqual(FundMenuEntry.covered(account: "BNI").subtitle, "Enough is there for the debit")
        XCTAssertEqual(FundMenuEntry.notCovered.title, "Not covered yet")
    }

    // MARK: - Paying lands on Funded when undone

    /// Confirming Done sets the flag when there is an Account, so un-ticking — or
    /// deleting the Expense from the ledger (§9.5) — lands on Funded, not Todo.
    @MainActor
    func testUndoingDoneLandsOnFunded() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let item = PlanItem(name: "Kirim buat Ibu", amount: 1_000_000, account: mandiri)
        context.insert(item)
        let expense = Expense(amount: 1_000_000, planItem: item)
        context.insert(expense)
        item.recordPaid()
        try context.save()
        XCTAssertEqual(PlanItemState.of(item), .done)

        context.delete(expense)
        try context.save()
        XCTAssertEqual(PlanItemState.of(item), .funded)
    }

    @MainActor
    func testPayingAnItemWithNoAccountLeavesTheFlagAlone() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Arisan kantor", amount: 200_000)
        context.insert(item)
        item.recordPaid()
        XCTAssertFalse(item.isFunded)
    }

    /// An Auto item posting itself is a payment too.
    @MainActor
    func testAnAutoPostingSetsFunded() throws {
        let context = try makeInMemoryContext()
        let calendar = Calendar(identifier: .gregorian)
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 20)))
        let plan = CyclePlan(cycleStart: start)
        let bni = Account(name: "BNI")
        [plan].forEach(context.insert)
        context.insert(bni)
        let withAccount = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 5,
                                   isAuto: true, plan: plan, account: bni)
        let without = PlanItem(name: "Netflix", amount: 130_000, dueDay: 5, isAuto: true, plan: plan)
        [withAccount, without].forEach(context.insert)
        try context.save()

        PlanMaintenance.run(in: context, now: now, payday: 1, calendar: calendar)

        XCTAssertTrue(withAccount.isFunded)
        XCTAssertFalse(without.isFunded)
    }

    // MARK: - Transfer lines

    /// An Envelope with an Account now adds its planned amount to that line
    /// (decision 26) — which it never did before.
    @MainActor
    func testAnEnvelopeWithAnAccountJoinsItsTransferLine() throws {
        let context = try makeInMemoryContext()
        let jago = Account(name: "Jago"), bca = Account(name: "BCA")
        [jago, bca].forEach(context.insert)
        let items = [PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago),
                     PlanItem(name: "Kebutuhan Kos", amount: 193_900, kind: .envelope, account: bca),
                     PlanItem(name: "Kos", amount: 2_200_000, account: bca),
                     PlanItem(name: "Jajan", amount: 100_000, kind: .envelope)]
        items.forEach(context.insert)
        try context.save()

        let rows = TransferLines.rows(activeItems: items, lines: [])
        XCTAssertEqual(rows.map(\.accountName), ["BCA", "Jago"])
        XCTAssertEqual(rows.map(\.planned), [2_393_900, 938_300])
        XCTAssertFalse(rows[1].allAuto, "an envelope's line reads 'send this', not 'keep this covered'")
    }

    /// Funded never touches the transfer tick, either way (decision 25).
    @MainActor
    func testFundedIsIndependentOfTheTransferTick() throws {
        let context = try makeInMemoryContext()
        let mandiri = Account(name: "Mandiri")
        context.insert(mandiri)
        let item = PlanItem(name: "Kirim buat Ibu", amount: 1_000_000, account: mandiri)
        context.insert(item)
        item.isFunded = true
        try context.save()

        let rows = TransferLines.rows(activeItems: [item], lines: [])
        XCTAssertFalse(try XCTUnwrap(rows.first).hasTransferred)

        let line = TransferLine(account: mandiri, hasTransferred: true)
        context.insert(line)
        item.isFunded = false
        try context.save()
        XCTAssertTrue(try XCTUnwrap(TransferLines.rows(activeItems: [item], lines: [line]).first).hasTransferred)
        XCTAssertEqual(PlanItemState.of(item), .todo)
    }

    // MARK: - The funded notice

    /// **Fixed only** (decision 30): an Envelope has nothing left to pay. Done items
    /// and items with no Account never count.
    @MainActor
    func testTheNoticeCountsFundedFixedItemsOnly() throws {
        let context = try makeInMemoryContext()
        let bni = Account(name: "BNI"), mandiri = Account(name: "Mandiri"),
            bca = Account(name: "BCA"), jago = Account(name: "Jago")
        [bni, mandiri, bca, jago].forEach(context.insert)
        let auto = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 25, isAuto: true, account: bni)
        let kirim = PlanItem(name: "Kirim buat Ibu", amount: 1_500_000, account: mandiri)
        let tarisa = PlanItem(name: "Tarisa Needs", amount: 1_500_000, account: bca)
        let kos = PlanItem(name: "Kos", amount: 2_200_000, account: bca)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago)
        let noAccount = PlanItem(name: "Arisan", amount: 200_000)
        let todo = PlanItem(name: "Bayar parkir", amount: 650_000, account: bca)
        let all = [auto, kirim, tarisa, kos, envelope, noAccount, todo]
        all.forEach(context.insert)
        [auto, kirim, tarisa, kos, envelope, noAccount].forEach { $0.isFunded = true }
        context.insert(Expense(amount: 2_200_000, planItem: kos))
        try context.save()

        let summary = FundedSummary(activeItems: all)
        XCTAssertEqual(summary.items.map(\.name), ["Cicilan Rumah BNI", "Kirim buat Ibu", "Tarisa Needs"])
        XCTAssertEqual(summary.total, 10_706_000)
        XCTAssertEqual(summary.title, "In the account, not yet paid")
        XCTAssertEqual(summary.detail, "3 items · " + Decimal(10_706_000).formattedIDR())
    }

    func testNoFundedItemsMeansNoNotice() {
        XCTAssertTrue(FundedSummary(activeItems: []).isEmpty)
    }

    /// L7: an item with no Account comes straight to E4, and the sheet says why.
    func testTheDoneSheetNamesAMissingAccount() {
        XCTAssertEqual(PlanCopy.doneSheetSubtitle(planned: 200_000, hasAccount: false),
                       "Fixed plan item · no account · planned " + Decimal(200_000).formattedIDR())
        XCTAssertEqual(PlanCopy.doneSheetSubtitle(planned: 2_200_000, hasAccount: true),
                       "Fixed plan item · planned " + Decimal(2_200_000).formattedIDR())
    }

    func testTheFilteredSectionTitleSaysHowManyOfHowMany() {
        XCTAssertEqual(PlanCopy.filteredSectionTitle(shown: 3, of: 14), "Plan · 3 of 14 items")
        XCTAssertEqual(PlanCopy.inAccount("Mandiri"), "in Mandiri")
    }

    // MARK: - Carry-over

    /// **A new cycle starts every item at Todo** (decision 31); the closed cycle keeps
    /// its Funded.
    @MainActor
    func testCarryOverResetsFunded() throws {
        let context = try makeInMemoryContext()
        let calendar = Calendar(identifier: .gregorian)
        func cycle(_ m: Int) throws -> PayCycle {
            PayCycle.containing(try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: m, day: 10))),
                                payday: 1, calendar: calendar)
        }
        let source = CyclePlan(cycleStart: try cycle(9).start)
        context.insert(source)
        let mandiri = Account(name: "Mandiri"), jago = Account(name: "Jago")
        [mandiri, jago].forEach(context.insert)
        let kirim = PlanItem(name: "Kirim buat Ibu", amount: 1_000_000, plan: source, account: mandiri)
        let hidup = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, plan: source, account: jago)
        [kirim, hidup].forEach(context.insert)
        [kirim, hidup].forEach { $0.isFunded = true }
        try context.save()

        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: try cycle(10), from: [source], in: context))

        let copied = copy.items ?? []
        XCTAssertEqual(copied.count, 2)
        XCTAssertTrue(copied.allSatisfy { !$0.isFunded })
        XCTAssertTrue(copied.allSatisfy { PlanItemState.of($0) == .todo })
        XCTAssertEqual(copied.first { $0.isEnvelope }?.account?.name, "Jago", "the Account itself is copied")
        XCTAssertTrue(kirim.isFunded && hidup.isFunded, "the old cycle keeps its Funded")
    }

    // MARK: - An older build on another device

    /// An older build never writes the field, so every item it creates or syncs down
    /// arrives with the default — Todo.
    @MainActor
    func testAnItemFromAnOlderBuildReadsAsTodo() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let item = PlanItem(name: "Kos", amount: 2_200_000, account: bca)
        context.insert(item)
        try context.save()
        XCTAssertFalse(item.isFunded)
        XCTAssertEqual(PlanItemState.of(item), .todo)
        XCTAssertEqual(DoneCheckState.state(for: item), .todo)
    }

    /// An older build confirms Done without setting the flag. Undoing that Done here
    /// lands on Todo rather than Funded — the pre-§7.6 behaviour, never a crash.
    @MainActor
    func testADoneFromAnOlderBuildUndoesToTodo() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let item = PlanItem(name: "Kos", amount: 2_200_000, account: bca)
        let expense = Expense(amount: 2_200_000, planItem: item)
        context.insert(item)
        context.insert(expense)
        try context.save()

        context.delete(expense)
        try context.save()
        XCTAssertEqual(PlanItemState.of(item), .todo)
    }

    /// An older build nils an Envelope's Account whenever it saves one. The flag it
    /// cannot see survives, but with no Account the envelope reads as plain Envelope
    /// again, leaves its transfer line, and offers no menu.
    @MainActor
    func testAnEnvelopeWhoseAccountAnOlderBuildClearedDegradesToTodo() throws {
        let context = try makeInMemoryContext()
        let jago = Account(name: "Jago")
        context.insert(jago)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, account: jago)
        context.insert(envelope)
        envelope.isFunded = true
        let line = TransferLine(account: jago, hasTransferred: true)
        context.insert(line)
        try context.save()
        XCTAssertEqual(DoneCheckState.state(for: envelope), .envelopeFunded)

        envelope.account = nil
        try context.save()

        XCTAssertEqual(PlanItemState.of(envelope), .todo)
        XCTAssertEqual(DoneCheckState.state(for: envelope), .envelope)
        XCTAssertEqual(DoneCheckTap.of(envelope), .none)
        XCTAssertTrue(TransferLines.rows(activeItems: [envelope], lines: [line]).isEmpty,
                      "a tick left behind for an account nothing plans from is ignored")
    }

    /// An older build leaves Envelopes off its transfer lines, so it can only ever
    /// tick an account a Fixed item uses. The tick it writes is an ordinary one here.
    @MainActor
    func testATickFromAnOlderBuildStillReadsHere() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let items = [PlanItem(name: "Kos", amount: 2_200_000, account: bca),
                     PlanItem(name: "Kebutuhan Kos", amount: 193_900, kind: .envelope, account: bca)]
        items.forEach(context.insert)
        let line = TransferLine(account: bca, hasTransferred: true)
        context.insert(line)
        try context.save()

        let row = try XCTUnwrap(TransferLines.rows(activeItems: items, lines: [line]).first)
        XCTAssertEqual(row.planned, 2_393_900)
        XCTAssertTrue(row.hasTransferred)
    }
}
