//
//  ExpressionEvaluatorTests.swift
//  ExpenseKuTests
//
//  Covers the calculator keypad's pure evaluation core: left-to-right (no
//  precedence) folding, live division, half-up whole-rupiah rounding, dangling
//  operators, backspace across an operator, clear, double-operator replacement,
//  and the single-decimal-per-token guard.
//

import XCTest
@testable import ExpenseKu

final class ExpressionEvaluatorTests: XCTestCase {

    /// Builds an evaluator by pressing each character of `keys` in order,
    /// mirroring how the keypad drives it.
    private func press(_ keys: String) -> ExpressionEvaluator {
        var e = ExpressionEvaluator()
        for c in keys {
            switch c {
            case "+": e.appendOperator(.add)
            case "−": e.appendOperator(.subtract)
            case "×": e.appendOperator(.multiply)
            case "÷": e.appendOperator(.divide)
            case ".": e.appendDecimal()
            default:  e.appendDigit(c)
            }
        }
        return e
    }

    func testLeftToRightNoPrecedence() {
        // 10000 + 5000 × 2 = 30000 (not 20000).
        XCTAssertEqual(press("10000+5000×2").committedAmount, 30000)
    }

    func testLiveDivision() {
        XCTAssertEqual(press("10000÷2").committedAmount, 5000)
    }

    func testDivisionRoundsHalfUpToWholeRupiah() {
        // 10000 / 3 = 3333.33… → 3333
        XCTAssertEqual(press("10000÷3").committedAmount, 3333)
        // 10000 / 8 = 1250 exactly.
        XCTAssertEqual(press("10000÷8").committedAmount, 1250)
        // 5 / 2 = 2.5 → 3 (half-up).
        XCTAssertEqual(press("5÷2").committedAmount, 3)
    }

    func testTrailingOperatorEvaluatesToLeftOperand() {
        XCTAssertEqual(press("10000÷").committedAmount, 10000)
    }

    func testEmptyIsZero() {
        XCTAssertEqual(press("").committedAmount, 0)
        XCTAssertFalse(press("").hasExpression)
    }

    func testLeadingOperatorIgnored() {
        var e = ExpressionEvaluator()
        e.appendOperator(.multiply)
        XCTAssertEqual(e.raw, "")
        XCTAssertEqual(e.committedAmount, 0)
    }

    func testDoubleOperatorReplacesLast() {
        // Pressing ÷ then × keeps only ×.
        let e = press("10000÷×2")
        XCTAssertEqual(e.raw, "10000×2")
        XCTAssertEqual(e.committedAmount, 20000)
    }

    func testBackspaceCrossesOperator() {
        var e = press("10000÷2")
        e.backspace()                 // "10000÷"
        XCTAssertEqual(e.committedAmount, 10000)
        e.backspace()                 // "10000"
        XCTAssertEqual(e.raw, "10000")
        XCTAssertFalse(e.hasExpression)
    }

    func testClear() {
        var e = press("123+456")
        e.clear()
        XCTAssertEqual(e.raw, "")
        XCTAssertEqual(e.committedAmount, 0)
    }

    func testSingleDecimalPerToken() {
        // Second "." in the same token is ignored.
        let e = press("10.5.5")
        XCTAssertEqual(e.raw, "10.55")
    }

    func testDecimalSeedsLeadingZero() {
        let e = press(".5")
        XCTAssertEqual(e.raw, "0.5")
    }

    func testLeadingZeroCollapses() {
        let e = press("007")
        XCTAssertEqual(e.raw, "7")
    }

    func testOperatorAfterDecimalDropsTrailingDot() {
        let e = press("10.÷2")
        XCTAssertEqual(e.raw, "10÷2")
        XCTAssertEqual(e.committedAmount, 5)
    }

    func testDisplayExpressionGroupsNumbers() {
        // Grouping separator is locale-dependent, so derive the expectation the
        // same way production does rather than hard-coding commas.
        let grouped = Decimal(1000000).formatted(.number.precision(.fractionLength(0)))
        XCTAssertEqual(press("1000000÷2").displayExpression, "\(grouped) ÷ 2")
    }

    func testDisplayExpressionEmptyForBareNumber() {
        XCTAssertEqual(press("1000000").displayExpression, "")
    }

    func testInitFromAmount() {
        let e = ExpressionEvaluator(amount: 42000)
        XCTAssertEqual(e.raw, "42000")
        XCTAssertEqual(e.committedAmount, 42000)
    }

    func testInitFromZeroAmountIsEmpty() {
        XCTAssertEqual(ExpressionEvaluator(amount: 0).raw, "")
    }
}
