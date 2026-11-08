//
//  ViewableReceiptTests.swift
//  ExpenseKuTests
//
//  docs/prd/receipt-reading.md §4.3.1: View receipt shows only while the form carries a
//  receipt.
//

import XCTest
@testable import ExpenseKu

nonisolated final class ViewableReceiptTests: XCTestCase {
    private let bca = Data("bca".utf8)
    private let shop = Data("indomaret".utf8)

    func testAFormFilledFromAReceiptShowsThatReceipt() {
        XCTAssertEqual(ViewableReceipt.image(filledFrom: bca, saved: nil, savedIsToCheck: false), bca)
    }

    func testEditingAnExpenseStillToCheckShowsItsSavedReceipt() {
        XCTAssertEqual(ViewableReceipt.image(filledFrom: nil, saved: shop, savedIsToCheck: true), shop)
    }

    func testAReceiptReadOnEditWinsOverTheSavedOne() {
        XCTAssertEqual(ViewableReceipt.image(filledFrom: bca, saved: shop, savedIsToCheck: true), bca)
    }

    func testAFormWithNoReceiptShowsNone() {
        XCTAssertNil(ViewableReceipt.image(filledFrom: nil, saved: nil, savedIsToCheck: false))
        XCTAssertNil(ViewableReceipt.image(filledFrom: nil, saved: shop, savedIsToCheck: false))
    }
}
