//
//  ReceiptCheckTests.swift
//  ExpenseKuTests
//
//  docs/prd/receipt-reading.md §4.7: only an expense carrying its receipt is one to check.
//  An Auto item's expense keeps Needs review after its item is deleted (PRD §9.4 of
//  cycle planning), and that one never came from a receipt.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class ReceiptCheckTests: XCTestCase {

    @MainActor
    func testAnExpenseSavedFromAReceiptIsToCheck() throws {
        let context = try makeInMemoryContext()
        let expense = Expense(amount: 62_500, needsReview: true)
        expense.receiptImage = Data([0xFF, 0xD8])
        context.insert(expense)
        try context.save()

        XCTAssertTrue(expense.isReceiptToCheck)
    }

    @MainActor
    func testAnAutoExpenseWhoseItemWasDeletedIsNotAReceipt() throws {
        let context = try makeInMemoryContext()
        let plan = CyclePlan(cycleStart: .now)
        context.insert(plan)
        let item = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, dueDay: 20, isAuto: true, plan: plan)
        context.insert(item)
        let expense = Expense(amount: 7_706_000, planItem: item, needsReview: true)
        context.insert(expense)
        try context.save()

        context.delete(item)
        try context.save()

        XCTAssertNil(expense.planItem)
        XCTAssertTrue(expense.needsReview)
        XCTAssertFalse(expense.isReceiptToCheck)
    }

    @MainActor
    func testCheckingClearsTheFlagAndTheImage() throws {
        let context = try makeInMemoryContext()
        let expense = Expense(amount: 62_500, needsReview: true)
        expense.receiptImage = Data([0xFF, 0xD8])
        context.insert(expense)

        expense.markReceiptChecked()

        XCTAssertFalse(expense.needsReview)
        XCTAssertNil(expense.receiptImage)
        XCTAssertFalse(expense.isReceiptToCheck)
    }
}
