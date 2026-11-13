//
//  ReceiptReadingTests.swift
//  ExpenseKuTests
//
//  docs/prd/receipt-reading.md §4.4, §4.6, §4.9 and ADR-0014's grounding rule, with the
//  PRD's sample: the BCA receipt "Rp 60.000 + biaya Rp 2.500, 22 Aug 14.28, to MUHAMMAD
//  FADHIL", now Sat 8 Nov 2026, 15.10.
//

import XCTest
@testable import ExpenseKu

nonisolated final class ReceiptReadingTests: XCTestCase {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .gmt
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    private var now: Date { at(2026, 11, 8, 15, 10) }

    private let bca = ReceiptText.lines([
        "BCA  m-Transfer",
        "Transfer Berhasil",
        "22 Agu 2026 14:28:05",
        "Tujuan  MUHAMMAD FADHIL",
        "Nominal  Rp 60.000,00",
        "Biaya  Rp 2.500,00",
        "Transfer 200x dapat cashback",
    ])

    private let indomaret = ReceiptText.lines([
        "INDOMARET",
        "Jl. Kaliurang Km 5",
        "08/11/2026 14:32",
        "AQUA 600ML  2  3.500  7.000",
        "ROTI TAWAR  1  21.600",
        "TOTAL  28.600",
        "TUNAI  50.000",
        "KEMBALI  21.400",
    ])

    // MARK: - Candidates

    func testMoneyIsFoundInBothStylesAndWithACurrency() {
        XCTAssertEqual(CandidateExtractor.amounts(in: "Rp 100.000,00"), [100_000])
        XCTAssertEqual(CandidateExtractor.amounts(in: "IDR 60,000.00"), [60_000])
        XCTAssertEqual(CandidateExtractor.amounts(in: "Rp 2500"), [2_500])
        XCTAssertEqual(CandidateExtractor.amounts(in: "-Rp 10.000"), [-10_000])
        XCTAssertEqual(CandidateExtractor.amounts(in: "Transfer 200x"), [])
    }

    func testDatesReadIndonesianMonthsAndSlashes() {
        XCTAssertEqual(CandidateExtractor.date(in: "22 Agu 2026 14:28:05"),
                       LocalDateTime(year: 2026, month: 8, day: 22, hour: 14, minute: 28))
        XCTAssertEqual(CandidateExtractor.date(in: "08/11/2026"),
                       LocalDateTime(year: 2026, month: 11, day: 8, hour: nil, minute: nil))
    }

    func testShortBankNamesCountOnlyInCapitals() {
        XCTAssertEqual(CandidateExtractor.bankBrands(in: "BCA m-Transfer"), ["bca"])
        XCTAssertEqual(CandidateExtractor.bankBrands(in: "abcabc"), [])
        XCTAssertEqual(CandidateExtractor.bankBrands(in: "Bank Danamon Indonesia"), ["danamon"])
    }

    // MARK: - §4.9 Rules

    func testRulesReadTheSampleTransfer() {
        let reading = ReceiptRules.read(bca, candidates: CandidateExtractor.extract(from: bca))
        XCTAssertEqual(reading.amount, 60_000)
        XCTAssertEqual(reading.fee, 2_500)
        XCTAssertEqual(reading.date, LocalDateTime(year: 2026, month: 8, day: 22, hour: 14, minute: 28))
        XCTAssertEqual(reading.bankBrandID, "bca")
        XCTAssertEqual(reading.counterparty, "MUHAMMAD FADHIL")
        XCTAssertNil(reading.categoryName)
    }

    func testRulesTakeTheTotalNotCashOrChange() {
        let reading = ReceiptRules.read(indomaret, candidates: CandidateExtractor.extract(from: indomaret))
        XCTAssertEqual(reading.amount, 28_600)
        XCTAssertNil(reading.fee)
        XCTAssertNil(reading.bankBrandID)
        XCTAssertEqual(reading.date, LocalDateTime(year: 2026, month: 11, day: 8, hour: 14, minute: 32))
    }

    func testRulesLeaveTheAmountWhenTwoLabelsDisagree() {
        let receipt = ReceiptText.lines(["Nominal  Rp 60.000", "Total  Rp 62.500"])
        XCTAssertNil(ReceiptRules.read(receipt, candidates: CandidateExtractor.extract(from: receipt)).amount)
    }

    func testRulesReadAValueUnderItsLabel() {
        let receipt = ReceiptText.lines(["Jumlah Transfer", "Rp 100.000", "Penerima", "Salsabila Arum Lukit"])
        let reading = ReceiptRules.read(receipt, candidates: CandidateExtractor.extract(from: receipt))
        XCTAssertEqual(reading.amount, 100_000)
        XCTAssertEqual(reading.counterparty, "Salsabila Arum Lukit")
    }

    func testRulesLeaveTheDateAndBankWhenThereAreTwo() {
        let receipt = ReceiptText.lines(["BCA  BRI", "01/11/2026", "02/11/2026"])
        let reading = ReceiptRules.read(receipt, candidates: CandidateExtractor.extract(from: receipt))
        XCTAssertNil(reading.date)
        XCTAssertNil(reading.bankBrandID)
    }

    // MARK: - ADR-0014 grounding

    func testTheModelPicksByIdBySpanOrByValue() {
        let candidates = CandidateExtractor.extract(from: bca)
        let byID = ReceiptResolver.resolve(answer: #"{"amount": "M1", "fee": "M2"}"#, receipt: bca,
                                           candidates: candidates, categories: [])
        XCTAssertEqual(byID.amount, 60_000)
        XCTAssertEqual(byID.fee, 2_500)

        let nominalSpan = try? XCTUnwrap(bca.spans.first { $0.text.hasPrefix("Rp 60") }).id
        let bySpan = ReceiptResolver.resolve(answer: "{\"amount\": \"\(nominalSpan ?? "")\"}", receipt: bca,
                                             candidates: candidates, categories: [])
        XCTAssertEqual(bySpan.amount, 60_000)

        let byValue = ReceiptResolver.resolve(answer: "```json\n{\"amount\": 60000, \"payer_bank\": \"bca\"}\n```",
                                              receipt: bca, candidates: candidates, categories: [])
        XCTAssertEqual(byValue.amount, 60_000)
        XCTAssertEqual(byValue.bankBrandID, "bca")
    }

    func testANumberNotOnTheReceiptIsNeverFilled() {
        let reading = ReceiptResolver.resolve(answer: #"{"amount": 200}"#, receipt: bca,
                                              candidates: CandidateExtractor.extract(from: bca), categories: [])
        XCTAssertNil(reading.amount)
    }

    func testTheCategoryMustBeOneOfTheOwners() {
        let candidates = CandidateExtractor.extract(from: bca)
        let known = ReceiptResolver.resolve(answer: #"{"category": "lovely support"}"#, receipt: bca,
                                            candidates: candidates, categories: ["Makan", "Lovely Support"])
        XCTAssertEqual(known.categoryName, "Lovely Support")
        let invented = ReceiptResolver.resolve(answer: #"{"category": "Transfer"}"#, receipt: bca,
                                               candidates: candidates, categories: ["Makan", "Lovely Support"])
        XCTAssertNil(invented.categoryName)
    }

    func testAnImplausibleAmountOrFeeIsDropped() {
        let small = ReceiptSanity.checked(ReceiptReading(amount: 300, fee: 2_500))
        XCTAssertNil(small.amount)
        XCTAssertNil(small.fee)
        let feeTooBig = ReceiptSanity.checked(ReceiptReading(amount: 10_000, fee: 10_000))
        XCTAssertEqual(feeTooBig.amount, 10_000)
        XCTAssertNil(feeTooBig.fee)
    }

    // MARK: - §4.4 Filling the form

    private let sample = ReceiptReading(amount: 60_000, fee: 2_500,
                                        date: LocalDateTime(year: 2026, month: 8, day: 22, hour: 14, minute: 28),
                                        bankBrandID: "bca", counterparty: "MUHAMMAD FADHIL",
                                        categoryName: "Lovely Support")

    private func emptyForm() -> ReceiptFill<String>.Form {
        .init(amountIsEmpty: true, dateIsUntouched: true, accountIsDefault: true, note: "",
              hasCategory: false, people: ["me"], clock: now)
    }

    private let accounts: [ReceiptFill<String>.AccountOption] = [
        .init(id: "jago", brandID: "jago", uses: 12),
        .init(id: "bca", brandID: "bca", uses: 4),
        .init(id: "bca-bisnis", brandID: "bca", uses: 1),
    ]

    private let people: [ReceiptFill<String>.NamedOption] = [
        .init(id: "me", name: "Randy"), .init(id: "tarisa", name: "Tarisa"), .init(id: "fadil", name: "Fadil"),
    ]

    private let categories: [ReceiptFill<String>.NamedOption] = [
        .init(id: "makan", name: "Makan"), .init(id: "lovely", name: "Lovely Support"),
    ]

    private func fill(_ reading: ReceiptReading, _ form: ReceiptFill<String>.Form,
                      people: [ReceiptFill<String>.NamedOption]? = nil) -> ReceiptFill<String> {
        ReceiptFill(reading: reading, form: form, accounts: accounts, people: people ?? self.people,
                    categories: categories, calendar: calendar)
    }

    func testAnEmptyFormTakesEverythingTheReceiptSays() {
        let result = fill(sample, emptyForm())
        XCTAssertEqual(result.expression, "60000+2500")
        XCTAssertEqual(ExpressionEvaluator(result.expression ?? "").committedAmount, 62_500)
        XCTAssertEqual(result.date, at(2026, 8, 22, 14, 28))
        XCTAssertEqual(result.account, .set("bca"))
        XCTAssertEqual(result.note, "MUHAMMAD FADHIL")
        XCTAssertNil(result.addedPerson)
        XCTAssertEqual(result.category, "lovely")
    }

    func testWhatTheOwnerTypedIsNeverReplaced() {
        var form = emptyForm()
        form.amountIsEmpty = false
        form.dateIsUntouched = false
        form.accountIsDefault = false
        form.note = "Kirim buat Fadhil"
        form.hasCategory = true
        let result = fill(sample, form)
        XCTAssertNil(result.expression)
        XCTAssertNil(result.date)
        XCTAssertEqual(result.account, .keep)
        XCTAssertNil(result.note)
        XCTAssertNil(result.category)
    }

    func testABankNoAccountWearsLeavesTheAccountNone() {
        var reading = sample
        reading.bankBrandID = "superbank"
        XCTAssertEqual(fill(reading, emptyForm()).account, .set(nil))
    }

    func testAReceiptWithNoBankKeepsTheDefaultAccount() {
        var reading = sample
        reading.bankBrandID = nil
        XCTAssertEqual(fill(reading, emptyForm()).account, .keep)
    }

    func testADateWithNoTimeKeepsTheFormsClock() {
        var reading = sample
        reading.date = LocalDateTime(year: 2026, month: 11, day: 7, hour: nil, minute: nil)
        XCTAssertEqual(fill(reading, emptyForm()).date, at(2026, 11, 7, 15, 10))
    }

    func testASharedReceiptWithoutADateKeepsItsShareTimeAcrossMidnight() {
        let sharedAt = at(2026, 11, 7, 23, 58)
        let item = ReceiptInboxItem(url: URL(filePath: "/inbox/\(Int(sharedAt.timeIntervalSince1970))-receipt.png"))
        var form = emptyForm()
        form.clock = item.addedAt
        var reading = sample
        reading.date = nil

        let result = fill(reading, form)

        XCTAssertNil(result.date)
        XCTAssertEqual(result.date ?? form.clock, sharedAt)
        XCTAssertNotEqual(result.date ?? form.clock, now)
    }

    func testASharedReceiptWithOnlyADateUsesTheShareClock() {
        var form = emptyForm()
        form.clock = at(2026, 11, 7, 23, 58)
        var reading = sample
        reading.date = LocalDateTime(year: 2026, month: 11, day: 6, hour: nil, minute: nil)

        XCTAssertEqual(fill(reading, form).date, at(2026, 11, 6, 23, 58))
    }

    func testASharedReceiptWithADateAndTimeOverridesTheShareTime() {
        var form = emptyForm()
        form.clock = at(2026, 11, 7, 23, 58)

        XCTAssertEqual(fill(sample, form).date, at(2026, 8, 22, 14, 28))
        form.dateIsUntouched = false
        XCTAssertNil(fill(sample, form).date)
    }

    func testAPersonMatchesOnTheLeadingWordsOfTheCounterparty() {
        var reading = sample
        reading.counterparty = "Salsabila Arum Lukit"
        let withSalsabila = people + [.init(id: "salsa", name: "salsabila")]
        XCTAssertEqual(fill(reading, emptyForm(), people: withSalsabila).addedPerson, "salsa")
        XCTAssertNil(fill(reading, emptyForm()).addedPerson)
    }

    func testTwoMatchingPeopleAddNeither() {
        var reading = sample
        reading.counterparty = "Salsabila Arum Lukit"
        let twins = people + [.init(id: "a", name: "Salsabila"), .init(id: "b", name: "Salsabila Arum")]
        XCTAssertNil(fill(reading, emptyForm(), people: twins).addedPerson)
    }

    func testAPersonAlreadyTaggedIsNotAddedAgain() {
        var reading = sample
        reading.counterparty = "Randy Efan Jaya Putra"
        XCTAssertNil(fill(reading, emptyForm()).addedPerson)
    }

    func testAReadingOfNothingFillsNothing() {
        XCTAssertFalse(fill(ReceiptReading(), emptyForm()).fillsAnything)
    }

    // MARK: - §4.6 Looks already logged

    func testTheSameAmountOnTheSameDayLooksLogged() {
        let logged: [ReceiptDuplicate.Logged<String>] = [
            .init(id: "earlier", amount: 62_500, date: at(2026, 8, 21, 20, 0)),
            .init(id: "same", amount: 62_500, date: at(2026, 8, 22, 9, 0)),
        ]
        XCTAssertEqual(ReceiptDuplicate.match(sample, in: logged, calendar: calendar), "same")
    }

    func testTheAmountWithoutItsFeeAlsoMatches() {
        let logged: [ReceiptDuplicate.Logged<String>] = [.init(id: "x", amount: 60_000, date: at(2026, 8, 22, 9, 0))]
        XCTAssertEqual(ReceiptDuplicate.match(sample, in: logged, calendar: calendar), "x")
    }

    func testAReadingWithoutADateIsNeverChecked() {
        var reading = sample
        reading.date = nil
        let logged: [ReceiptDuplicate.Logged<String>] = [.init(id: "x", amount: 62_500, date: at(2026, 8, 22, 9, 0))]
        XCTAssertNil(ReceiptDuplicate.match(reading, in: logged, calendar: calendar))
    }
}
