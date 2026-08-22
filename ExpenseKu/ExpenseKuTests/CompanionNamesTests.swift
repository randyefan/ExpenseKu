//
//  CompanionNamesTests.swift
//  ExpenseKuTests
//
//  The companion phrase under an expense row. It branches on count and used to end
//  in a force unwrap, so the boundaries are worth pinning.
//

import XCTest
@testable import ExpenseKu

nonisolated final class CompanionNamesTests: XCTestCase {

    func testNoCompanionsIsEmpty() {
        XCTAssertEqual(CompanionNames.phrase(names: []), "")
    }

    func testNilCompanionsIsEmpty() {
        XCTAssertEqual(CompanionNames.phrase(nil), "")
    }

    func testOneCompanionHasNoConjunction() {
        XCTAssertEqual(CompanionNames.phrase(names: ["Tarisa"]), "Tarisa")
    }

    /// Two take "and" with no comma.
    func testTwoCompanionsJoinWithAnd() {
        XCTAssertEqual(CompanionNames.phrase(names: ["Tarisa", "Fadil"]), "Fadil and Tarisa")
    }

    /// Three or more take the Oxford comma — the branch that held the force unwrap.
    func testThreeCompanionsUseOxfordComma() {
        XCTAssertEqual(
            CompanionNames.phrase(names: ["Me", "Anas", "Beni"]),
            "Anas, Beni, and Me"
        )
    }

    func testFourCompanionsUseOxfordComma() {
        XCTAssertEqual(
            CompanionNames.phrase(names: ["Deni", "Anas", "Citra", "Budi"]),
            "Anas, Budi, Citra, and Deni"
        )
    }

    /// Always alphabetical, so the same set reads the same however it was entered.
    func testOrderIsIndependentOfInput() {
        let a = CompanionNames.phrase(names: ["Tarisa", "Budi", "Anas"])
        let b = CompanionNames.phrase(names: ["Anas", "Tarisa", "Budi"])
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, "Anas, Budi, and Tarisa")
    }

    /// Duplicates are not collapsed — two people may genuinely share a name, and the
    /// row should not silently hide one of them.
    func testDuplicateNamesBothAppear() {
        XCTAssertEqual(CompanionNames.phrase(names: ["Budi", "Budi"]), "Budi and Budi")
    }

    /// An empty name does not crash or produce a stray separator run.
    func testEmptyNameIsTolerated() {
        XCTAssertEqual(CompanionNames.phrase(names: ["", "Budi"]), " and Budi")
    }
}
