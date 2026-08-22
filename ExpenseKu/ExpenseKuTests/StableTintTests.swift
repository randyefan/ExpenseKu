//
//  StableTintTests.swift
//  ExpenseKuTests
//
//  Auto tints must survive a relaunch. `Theme.categoryTint` used `String.hashValue`,
//  which Swift seeds randomly per process, so a category with no owner-chosen colour
//  was repainted every launch — "Kopi" green one run, blue the next.
//
//  These pin the index to fixed expected values rather than merely calling the
//  function twice: within a single process `hashValue` *is* stable, so a
//  same-process comparison would not catch a regression. Fixed values would.
//

import XCTest
@testable import ExpenseKu

nonisolated final class StableTintTests: XCTestCase {

    /// The seven auto hues in `categoryTint`.
    private let hueCount = 7
    /// The twelve palette swatches in `AppearancePalette`.
    private let swatchCount = 12

    /// Names from the sample data, pinned. If `stableIndex` goes back to
    /// `hashValue` these become random per run and this fails.
    func testKnownNamesMapToKnownIndices() {
        XCTAssertEqual(Theme.stableIndex("Kopi", upperBound: hueCount), 2)
        XCTAssertEqual(Theme.stableIndex("Makan", upperBound: hueCount), 0)
        XCTAssertEqual(Theme.stableIndex("Transport", upperBound: hueCount), 4)
        XCTAssertEqual(Theme.stableIndex("Cash", upperBound: hueCount), 5)
        XCTAssertEqual(Theme.stableIndex("GoPay", upperBound: hueCount), 6)
        XCTAssertEqual(Theme.stableIndex("Me", upperBound: hueCount), 3)
    }

    /// The same names against the wider palette, so a change to the hue count alone
    /// cannot make the test above pass by accident.
    func testKnownNamesMapToKnownSwatchIndices() {
        XCTAssertEqual(Theme.stableIndex("Kopi", upperBound: swatchCount), 4)
        XCTAssertEqual(Theme.stableIndex("Makan", upperBound: swatchCount), 3)
        XCTAssertEqual(Theme.stableIndex("Transport", upperBound: swatchCount), 2)
    }

    /// Always in range, including for the empty name the appearance picker starts on.
    func testIndexIsAlwaysInRange() {
        for name in ["", " ", "a", "Kopi", "Kopi ", "kopi", "☕️", String(repeating: "x", count: 500)] {
            let index = Theme.stableIndex(name, upperBound: hueCount)
            XCTAssertTrue((0..<hueCount).contains(index), "\(name) produced \(index)")
        }
    }

    /// Different names should not all collapse onto one hue.
    func testDistinctNamesSpreadAcrossHues() {
        let names = ["Makan", "Transport", "Kopi", "Cash", "GoPay", "Me", "Tarisa",
                     "Groceries", "Rent", "Fuel", "Coffee", "Gift"]
        let used = Set(names.map { Theme.stableIndex($0, upperBound: hueCount) })
        XCTAssertGreaterThanOrEqual(used.count, 5, "only \(used.count) of \(hueCount) hues used")
    }

    /// Trimming and casing are not normalised away — "Kopi" and "kopi" are different
    /// categories to the owner, so they may differ here too. Pinned so the behaviour
    /// is a decision rather than an accident.
    func testCaseAffectsTheTint() {
        XCTAssertNotEqual(
            Theme.stableIndex("Kopi", upperBound: hueCount),
            Theme.stableIndex("kopi", upperBound: hueCount)
        )
    }
}
