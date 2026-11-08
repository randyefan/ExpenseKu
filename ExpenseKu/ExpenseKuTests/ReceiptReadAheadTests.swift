//
//  ReceiptReadAheadTests.swift
//  ExpenseKuTests
//
//  docs/prd/receipt-reading.md §4.11 with its sample: three receipts waiting, the BCA
//  transfer read by Gemma, the others not yet read.
//

import XCTest
@testable import ExpenseKu

nonisolated final class ReceiptReadAheadTests: XCTestCase {

    private var folder: ReceiptInboxFolder!

    override func setUpWithError() throws {
        folder = ReceiptInboxFolder(url: FileManager.default.temporaryDirectory
            .appending(path: "ReadAhead-\(UUID().uuidString)", directoryHint: .isDirectory))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder.url)
    }

    private let bca = ReceiptReading(amount: 60_000, fee: 2_500,
                                     date: LocalDateTime(year: 2026, month: 8, day: 22, hour: 14, minute: 28),
                                     bankBrandID: "bca", counterparty: "MUHAMMAD FADHIL", categoryName: nil)

    private func waiting(_ count: Int) throws -> [ReceiptInboxItem] {
        try (0..<count).map { index in
            try folder.add(Data("receipt \(index)".utf8), fileExtension: "png",
                           now: Date(timeIntervalSince1970: 1_000 + TimeInterval(index)))
        }
    }

    // MARK: - Which receipts a pass reads

    func testAPassReadsTheUnreadReceiptsOldestFirst() throws {
        let items = try waiting(3)
        let stored = [items[0].id: StoredReceiptReading(reading: bca, hadModel: true)]

        let toRead = ReadAheadPlan.receiptsToRead(items, stored: stored, modelIsReady: true)

        XCTAssertEqual(toRead, [items[1], items[2]])
    }

    func testARulesReadingIsReadAgainOnlyOnceTheModelIsReady() throws {
        let items = try waiting(1)
        let stored = [items[0].id: StoredReceiptReading(reading: bca, hadModel: false)]

        XCTAssertEqual(ReadAheadPlan.receiptsToRead(items, stored: stored, modelIsReady: false), [])
        XCTAssertEqual(ReadAheadPlan.receiptsToRead(items, stored: stored, modelIsReady: true), items)
    }

    func testAnEmptyReadingTheModelWasAskedForIsNotRetried() throws {
        let items = try waiting(1)
        let stored = [items[0].id: StoredReceiptReading(reading: ReceiptReading(), hadModel: true)]

        XCTAssertEqual(ReadAheadPlan.receiptsToRead(items, stored: stored, modelIsReady: true), [])
    }

    // MARK: - The banner's caption (AG10, AG11)

    func testTheCaptionCountsTheReceiptInHandWhileReading() throws {
        let items = try waiting(3)
        let progress = ReadAheadProgress(position: 2, total: 3)

        XCTAssertEqual(ReceiptInboxCaption.make(waiting: items, readIDs: [items[0].id], progress: progress),
                       .reading(progress))
    }

    func testTheCaptionSaysReadyOnceEveryWaitingReceiptIsRead() throws {
        let items = try waiting(3)

        XCTAssertEqual(ReceiptInboxCaption.make(waiting: items, readIDs: Set(items.map(\.id)), progress: nil),
                       .ready)
    }

    func testAPassStoppedMidwayFallsBackToTheSharedCaption() throws {
        let items = try waiting(3)

        XCTAssertEqual(ReceiptInboxCaption.make(waiting: items, readIDs: [items[0].id], progress: nil), .shared)
    }

    // MARK: - Kept beside the receipt

    func testAReadingIsKeptBesideItsReceiptAndNeverTakenForOne() throws {
        let items = try waiting(2)
        let stored = StoredReceiptReading(reading: bca, hadModel: true)

        folder.store(stored, for: items[0])

        XCTAssertEqual(folder.storedReading(for: items[0]), stored)
        XCTAssertNil(folder.storedReading(for: items[1]))
        XCTAssertEqual(folder.items(), items)
    }

    @MainActor
    func testRemovingAReceiptRemovesItsReading() throws {
        let items = try waiting(1)
        folder.store(StoredReceiptReading(reading: bca, hadModel: true), for: items[0])
        let inbox = ReceiptInbox(folder: folder)

        inbox.remove(items[0])

        XCTAssertNil(folder.storedReading(for: items[0]))
        let left = try FileManager.default.contentsOfDirectory(atPath: folder.url.path(percentEncoded: false))
        XCTAssertEqual(left, [])
    }
}
