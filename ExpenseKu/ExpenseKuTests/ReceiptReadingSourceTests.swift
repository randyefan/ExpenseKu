//
//  ReceiptReadingSourceTests.swift
//  ExpenseKuTests
//
//  docs/prd/reading-source.md §4.1–§4.4, with the PRD's sample: the BCA receipt
//  "Rp 60.000 + biaya Rp 2.500, 22 Aug 14.28, to MUHAMMAD FADHIL".
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class ReceiptReadingSourceTests: XCTestCase {

    private let bca = ReceiptText.lines([
        "BCA  m-Transfer",
        "Transfer Berhasil",
        "22 Agu 2026 14:28:05",
        "Tujuan  MUHAMMAD FADHIL",
        "Nominal  Rp 60.000,00",
        "Biaya  Rp 2.500,00",
    ])

    private func read(hadModel: Bool, answer: String?) -> StoredReceiptReading {
        ReceiptReader.reading(of: bca, candidates: CandidateExtractor.extract(from: bca), categories: ["Transfer"],
                              hadModel: hadModel, answer: answer)
    }

    // MARK: - §4.1 The reading's source

    func testAModelAnswerThatFillsAFieldIsGemma() {
        let stored = read(hadModel: true, answer: #"{"amount": "M1", "fee": "M2", "category": "Transfer"}"#)
        XCTAssertEqual(stored.source, .gemma)
        XCTAssertEqual(stored.reading.categoryName, "Transfer")
        XCTAssertEqual(stored.shownSource, .gemma)
    }

    func testWithoutAModelTheRulesReadItAsOCRWithNoModel() {
        let stored = read(hadModel: false, answer: nil)
        XCTAssertEqual(stored.source, .ocrNoModel)
        XCTAssertEqual(stored.reading.amount, 60_000)
        XCTAssertNil(stored.reading.categoryName)
    }

    func testAModelThatAnswersNothingUsableIsOCRGemmaCouldNotRead() {
        XCTAssertEqual(read(hadModel: true, answer: #"{"amount": 200}"#).source, .ocrModelFailed)
        XCTAssertEqual(read(hadModel: true, answer: "not json").source, .ocrModelFailed)
        XCTAssertEqual(read(hadModel: true, answer: nil).source, .ocrModelFailed)
        XCTAssertEqual(read(hadModel: true, answer: nil).reading.amount, 60_000)
    }

    func testAReadingThatFilledNothingShowsNoSource() {
        let stored = StoredReceiptReading(reading: ReceiptReading(), hadModel: false, source: .ocrNoModel)
        XCTAssertNil(stored.shownSource)
    }

    func testAReadingKeptBeforeThisFeatureShowsNoSource() throws {
        let json = Data(#"{"reading": {"amount": 60000}, "hadModel": true}"#.utf8)
        let stored = try JSONDecoder().decode(StoredReceiptReading.self, from: json)
        XCTAssertEqual(stored.reading.amount, 60_000)
        XCTAssertNil(stored.shownSource)
    }

    func testASourceSurvivesBeingKeptBesideItsReceipt() throws {
        let stored = read(hadModel: true, answer: nil)
        let kept = try JSONDecoder().decode(StoredReceiptReading.self, from: JSONEncoder().encode(stored))
        XCTAssertEqual(kept.source, .ocrModelFailed)
    }

    // MARK: - §4.2 The card on the form

    func testTheWordsSayOCRIsNotAIAndGemmaIs() {
        XCTAssertEqual(ReceiptReadingSource.gemma.title, "Read by Gemma AI")
        XCTAssertEqual(ReceiptReadingSource.ocrNoModel.title, "Read by OCR, no AI")
        XCTAssertEqual(ReceiptReadingSource.ocrModelFailed.title, "Read by OCR, no AI")
        XCTAssertTrue(ReceiptReadingSource.gemma.caption(modelIsReady: true).contains("AI model"))
        XCTAssertTrue(ReceiptReadingSource.ocrNoModel.caption(modelIsReady: false).contains("it isn't AI"))
        XCTAssertTrue(ReceiptReadingSource.ocrModelFailed.caption(modelIsReady: true).contains("couldn't read this receipt"))
    }

    func testOnlyTheNoModelCardOffersTheDownloadWhileTheModelIsMissing() {
        XCTAssertTrue(ReceiptReadingSource.ocrNoModel.offersDownload(modelIsReady: false))
        XCTAssertFalse(ReceiptReadingSource.ocrNoModel.offersDownload(modelIsReady: true))
        XCTAssertFalse(ReceiptReadingSource.ocrModelFailed.offersDownload(modelIsReady: false))
        XCTAssertFalse(ReceiptReadingSource.gemma.offersDownload(modelIsReady: false))
    }

    func testTheNoModelCaptionDropsTheDownloadOnceTheModelIsReady() {
        XCTAssertTrue(ReceiptReadingSource.ocrNoModel.caption(modelIsReady: false).hasSuffix("in Receipt reading."))
        XCTAssertEqual(ReceiptReadingSource.ocrNoModel.caption(modelIsReady: true),
                       "OCR only recognises text — it isn't AI, so Category is left for you.")
    }

    func testGemmaWearsSparklesAndOCRTheTextViewfinder() {
        XCTAssertEqual(ReceiptReadingSource.gemma.systemImage, "sparkles")
        XCTAssertEqual(ReceiptReadingSource.ocrNoModel.systemImage, "text.viewfinder")
        XCTAssertEqual(ReceiptReadingSource.ocrModelFailed.systemImage, "text.viewfinder")
    }

    // MARK: - §4.3 Saving the source, §4.4 the To check sheet

    @MainActor
    func testAnExpenseKeepsWhoReadItsReceiptUntilItIsChecked() throws {
        let context = try makeInMemoryContext()
        let expense = Expense(amount: 62_500, needsReview: true)
        expense.receiptImage = Data([0xFF, 0xD8])
        expense.receiptSource = .ocrNoModel
        context.insert(expense)
        try context.save()

        XCTAssertEqual(expense.receiptSourceValue, "ocrNoModel")
        XCTAssertEqual(expense.receiptSource, .ocrNoModel)

        expense.markReceiptChecked()

        XCTAssertNil(expense.receiptSource)
        XCTAssertNil(expense.receiptSourceValue)
    }

    func testTheSheetTagDropsTheReason() {
        XCTAssertEqual(ReceiptReadingSource.gemma.tag, "Gemma AI")
        XCTAssertEqual(ReceiptReadingSource.ocrNoModel.tag, "OCR, no AI")
        XCTAssertEqual(ReceiptReadingSource.ocrModelFailed.tag, "OCR, no AI")
    }

    @MainActor
    func testAReceiptSavedBeforeV9HasNoSource() throws {
        let context = try makeInMemoryContext()
        let expense = Expense(amount: 62_500, needsReview: true)
        expense.receiptImage = Data([0xFF, 0xD8])
        context.insert(expense)
        try context.save()

        XCTAssertNil(expense.receiptSource)
    }

    func testAnUnknownSavedValueReadsAsNoSource() {
        XCTAssertNil(ReceiptReadingSource(rawValue: "vision"))
    }
}
