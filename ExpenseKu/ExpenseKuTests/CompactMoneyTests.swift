//
//  CompactMoneyTests.swift
//  ExpenseKuTests
//
//  Behaviour oracle for the compact amount shown above a Spend over Time bar.
//  Assertions avoid exact strings so the suite holds under any locale: what
//  matters is that a fractional millions value keeps its digit and a round
//  value does not grow a ",0" tail.
//

import XCTest
@testable import ExpenseKu

nonisolated final class CompactMoneyTests: XCTestCase {

    /// Two amounts that round to the same million must still read differently.
    func testMillionsKeepOneDecimal() {
        let fractional = Decimal(11_250_000).compactAmount()
        let round = Decimal(11_000_000).compactAmount()

        XCTAssertNotEqual(fractional, round, "11.25M collapsed onto 11M: \(fractional)")
    }

    /// A round amount carries no decimal separator — no "220,0RB".
    func testRoundAmountsCarryNoDecimal() {
        let label = Decimal(220_000).compactAmount()

        XCTAssertFalse(label.contains(","), "unexpected decimal in \(label)")
        XCTAssertFalse(label.contains("."), "unexpected decimal in \(label)")
    }

    /// A half unit rounds away from zero, so 11,25 million reads as 11,3 —
    /// not the 11,2 that the default half-even rule would give.
    func testHalfRoundsUp() {
        XCTAssertEqual(Decimal(11_250_000).compactAmount(), Decimal(11_300_000).compactAmount())
    }
}
