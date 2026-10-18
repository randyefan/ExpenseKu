//
//  ExpenseRowLeadTests.swift
//  ExpenseKuTests
//
//  What leads an expense row (docs/prd/bank-logos.md §5.5, amended by flow Z): the
//  Account's mark with the category as a badge, or the category icon alone. One test per
//  row of the §5.5 tables, with ZA1's and ZA3's sample cases.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class ExpenseRowLeadTests: XCTestCase {

    func testAnAccountWithALogoLeads() {
        XCTAssertEqual(ExpenseRowLead.resolve(hasAccount: true, accountsLead: true), .account)
    }

    func testAnAccountWithoutALogoStillLeads() {
        let cash = ExpenseRowLead.resolve(hasAccount: true, accountsLead: true)

        XCTAssertEqual(cash, .account, "the mark draws the Account's own symbol, but the Account still leads")
    }

    func testAnUnassignedExpenseLeadsWithItsCategory() {
        let lead = ExpenseRowLead.resolve(hasAccount: false, accountsLead: true)

        XCTAssertEqual(lead, .category)
        XCTAssertFalse(lead.showsBadge)
        XCTAssertFalse(lead.showsAccountName)
    }

    func testTheAccountLeadCarriesTheBadgeAndTheName() {
        XCTAssertTrue(ExpenseRowLead.account.showsBadge)
        XCTAssertTrue(ExpenseRowLead.account.showsAccountName)
    }

    func testAListThatTurnsAccountsOffLeadsWithTheCategory() {
        XCTAssertEqual(ExpenseRowLead.resolve(hasAccount: true, accountsLead: false), .category)
    }

    @MainActor
    func testOneAccountsDrillInKeepsTheCategoryFirstRow() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA Gaji")
        context.insert(bca)
        try context.save()

        XCTAssertFalse(ExpenseRowLead.accountsLead(subject: .account(bca.persistentModelID), narrowing: nil))
    }

    @MainActor
    func testACategoryDrillInLetsAccountsLead() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        try context.save()

        XCTAssertTrue(ExpenseRowLead.accountsLead(subject: .category(makan.persistentModelID), narrowing: nil))
        XCTAssertTrue(ExpenseRowLead.accountsLead(subject: .uncategorized, narrowing: nil))
    }

    @MainActor
    func testACategoryDrillInNarrowedToOneAccountKeepsTheCategoryFirstRow() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let bca = Account(name: "BCA Gaji")
        context.insert(makan)
        context.insert(bca)
        try context.save()

        XCTAssertFalse(ExpenseRowLead.accountsLead(subject: .category(makan.persistentModelID),
                                                   narrowing: .account(bca.persistentModelID)))
    }

    func testTheUnassignedDrillInHasNoAccountToLead() {
        XCTAssertFalse(ExpenseRowLead.accountsLead(subject: .unassigned, narrowing: nil))
    }
}
