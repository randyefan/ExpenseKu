import XCTest
@testable import ExpenseKu

nonisolated final class ReceiptDescriptionTests: XCTestCase {
    private let receipt = ReceiptText.lines([
        "KOPI KENANGAN", "KOPI SUSU  25.000", "ROTI  15.000", "TOTAL  40.000"
    ])

    private func resolve(_ answer: String) -> ReceiptReading {
        ReceiptResolver.resolve(answer: answer, receipt: receipt,
                                candidates: CandidateExtractor.extract(from: receipt),
                                categories: ["Makan", "Transport"])
    }

    private func fill(_ reading: ReceiptReading, note: String = "", untouched: Bool = true) -> ReceiptFill<String> {
        ReceiptFill(reading: reading,
                    form: .init(amountIsEmpty: true, dateIsUntouched: true, accountIsDefault: true,
                                note: note, noteIsUntouched: untouched, hasCategory: false,
                                people: [], clock: .now),
                    accounts: [], people: [.init(id: "friend", name: "KOPI KENANGAN")],
                    categories: [.init(id: "food", name: "Makan")], calendar: .current)
    }

    func testDescriptionAndKnownCategoryReachTheExpenseForm() {
        let reading = resolve(#"{"description":"Kopi dan roti di Kopi Kenangan","category":"Makan","counterparty":"KOPI KENANGAN"}"#)
        let result = fill(reading)

        XCTAssertEqual(result.note, "Kopi dan roti di Kopi Kenangan")
        XCTAssertEqual(result.category, "food")
        XCTAssertEqual(reading.counterparty, "KOPI KENANGAN")
        XCTAssertEqual(result.addedPerson, "friend")
    }

    func testDescriptionCannotCreateACategoryOrAnAmount() {
        let reading = resolve(#"{"description":"Kopi dan roti di Kopi Kenangan","category":"Coffee","amount":999999}"#)

        XCTAssertEqual(reading.expenseDescription, "Kopi dan roti di Kopi Kenangan")
        XCTAssertNil(reading.categoryName)
        XCTAssertNil(reading.amount)
    }

    func testOwnerWrittenDescriptionIsKept() {
        let result = fill(resolve(#"{"description":"Kopi dan roti di Kopi Kenangan"}"#), note: "Sarapan bersama teman")
        XCTAssertNil(result.note)
    }

    func testDeliberatelyClearedDescriptionStaysEmptyOnAnotherReading() {
        let reading = resolve(#"{"description":"Kopi dan roti di Kopi Kenangan","counterparty":"KOPI KENANGAN"}"#)
        XCTAssertNil(fill(reading, untouched: false).note)
    }

    func testWhitespaceIsNormalizedIntoOneLine() {
        let reading = resolve(#"{"description":"  Kopi dan\nroti   di Kopi Kenangan  "}"#)
        XCTAssertEqual(reading.expenseDescription, "Kopi dan roti di Kopi Kenangan")
    }

    func testUnusableDescriptionFallsBackToTheCounterparty() throws {
        let invalid: [Any] = [NSNull(), "", " \n ", "null", "NONE", 12345, ["kopi"], String(repeating: "a", count: 161)]
        for description in invalid {
            let data = try JSONSerialization.data(withJSONObject: [
                "description": description, "counterparty": "KOPI KENANGAN"
            ])
            let reading = resolve(String(decoding: data, as: UTF8.self))

            XCTAssertNil(reading.expenseDescription)
            XCTAssertEqual(fill(reading).note, "KOPI KENANGAN")
        }
    }

    func testDescriptionAtTheLimitIsAccepted() {
        let reading = ReceiptSanity.checked(ReceiptReading(expenseDescription: String(repeating: "a", count: 160)))
        XCTAssertEqual(reading.expenseDescription?.count, 160)
    }

    func testDescriptionAloneCountsAsAReading() {
        let reading = resolve(#"{"description":"Transfer ke Budi"}"#)
        XCTAssertFalse(reading.isEmpty)
        XCTAssertEqual(fill(reading).note, "Transfer ke Budi")
    }

    func testOlderReadingStillDecodesAndIsReanalyzedWhenGemmaIsReady() throws {
        let data = Data(#"{"reading":{"counterparty":"BUDI"},"hadModel":true,"source":"gemma"}"#.utf8)
        let stored = try JSONDecoder().decode(StoredReceiptReading.self, from: data)

        XCTAssertEqual(stored.reading.counterparty, "BUDI")
        XCTAssertNil(stored.reading.expenseDescription)
        XCTAssertNil(stored.analysisVersion)
        XCTAssertTrue(ReadAheadPlan.needsReading(stored, modelIsReady: true))
        XCTAssertFalse(ReadAheadPlan.needsReading(stored, modelIsReady: false))
    }

    func testPreviousDescriptionAnalysisIsRefreshedForPocketContext() throws {
        let data = Data(#"{"reading":{"expenseDescription":"Transfer ke Budi"},"hadModel":true,"source":"gemma","analysisVersion":2}"#.utf8)
        let stored = try JSONDecoder().decode(StoredReceiptReading.self, from: data)

        XCTAssertTrue(ReadAheadPlan.needsReading(stored, modelIsReady: true))
        XCTAssertFalse(ReadAheadPlan.needsReading(stored, modelIsReady: false))
    }

    func testCurrentAnalysisRoundTripsAndIsNotReadAgain() throws {
        let reading = resolve(#"{"description":"Kopi dan roti di Kopi Kenangan","category":"Makan"}"#)
        let stored = StoredReceiptReading(reading: reading, hadModel: true, source: .gemma)
        let decoded = try JSONDecoder().decode(StoredReceiptReading.self, from: JSONEncoder().encode(stored))

        XCTAssertEqual(decoded, stored)
        XCTAssertEqual(decoded.analysisVersion, StoredReceiptReading.currentAnalysisVersion)
        XCTAssertFalse(ReadAheadPlan.needsReading(decoded, modelIsReady: true))
    }
}
