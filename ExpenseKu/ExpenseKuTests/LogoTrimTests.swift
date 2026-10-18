//
//  LogoTrimTests.swift
//  ExpenseKuTests
//
//  docs/prd/bank-logos.md §5.5: the wordmark chip draws a logo cropped to the pixels
//  that carry ink.
//

import XCTest
import UIKit
@testable import ExpenseKu

nonisolated final class LogoTrimTests: XCTestCase {
    private func alpha(_ rows: [String]) -> [UInt8] {
        rows.flatMap { $0.map { $0 == "#" ? UInt8(255) : $0 == "." ? 4 : 0 } }
    }

    func testABandInTheMiddleIsAllThatIsKept() {
        let pixels = alpha([
            "      ",
            " #### ",
            "##  ##",
            "      ",
        ])
        XCTAssertEqual(LogoTrim.opaqueBounds(alpha: pixels, width: 6, height: 4),
                       CGRect(x: 0, y: 1, width: 6, height: 2))
    }

    func testASinglePixelIsItsOwnBounds() {
        let pixels = alpha([
            "   ",
            "  #",
            "   ",
        ])
        XCTAssertEqual(LogoTrim.opaqueBounds(alpha: pixels, width: 3, height: 3),
                       CGRect(x: 2, y: 1, width: 1, height: 1))
    }

    func testNearTransparentNoiseDoesNotHoldTheBoundsOpen() {
        let pixels = alpha([
            ".   .",
            "  #  ",
            ".   .",
        ])
        XCTAssertEqual(LogoTrim.opaqueBounds(alpha: pixels, width: 5, height: 3),
                       CGRect(x: 2, y: 1, width: 1, height: 1))
    }

    func testAnEmptyImageHasNoBounds() {
        XCTAssertNil(LogoTrim.opaqueBounds(alpha: alpha(["   ", "...", "   "]), width: 3, height: 3))
        XCTAssertNil(LogoTrim.opaqueBounds(alpha: [], width: 0, height: 0))
    }

    @MainActor
    func testSnapshotWordmarksLoseTheirBandsAndSquareMarksStayWhole() throws {
        let squareMarks: Set = ["bri", "dana"]
        for logo in BankLogo.snapshot {
            let image = try XCTUnwrap(UIImage(named: logo.assetName), logo.id)
            let trimmed = image.trimmedToOpaque()
            XCTAssertEqual(trimmed.size.width, image.size.width, accuracy: 1, logo.id)
            if squareMarks.contains(logo.id) {
                XCTAssertEqual(trimmed.size.height, image.size.height, accuracy: 1, logo.id)
            } else {
                XCTAssertLessThan(trimmed.size.height, image.size.height * 0.5, logo.id)
            }
        }
    }
}
