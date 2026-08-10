//
//  CategoryAppearanceTests.swift
//  ExpenseKuTests
//
//  Covers the owner-customizable appearance (color + icon) on Category/Account:
//  the resolved-symbol fallbacks, the per-type "auto" glyph, and the hex/HSB
//  helpers the palette round-trips through. Uses un-inserted model objects so the
//  tests stay pure — same pattern as the analytics tests.
//

import XCTest
@testable import ExpenseKu

// See AccountAnalyticsTests: pin the ambiguous `Category` name to our model.
private typealias Category = ExpenseKu.Category

final class CategoryAppearanceTests: XCTestCase {

    // MARK: - Resolved symbol

    /// With no explicit icon, a category infers its glyph from the name.
    func testCategoryResolvedSymbolFallsBackToName() {
        XCTAssertEqual(Category(name: "Makan").resolvedSymbol, "fork.knife")
        XCTAssertEqual(Category(name: "Kopi").resolvedSymbol, "cup.and.saucer.fill")
        // An unrecognised name lands on the neutral tag.
        XCTAssertEqual(Category(name: "Zxywv").resolvedSymbol, "tag.fill")
    }

    /// An explicit icon always wins over the name-derived one.
    func testCategoryResolvedSymbolPrefersExplicit() {
        let c = Category(name: "Makan", iconName: "gift.fill")
        XCTAssertEqual(c.resolvedSymbol, "gift.fill")
    }

    /// An account with no icon uses the shared card default, not a name guess.
    func testAccountResolvedSymbolDefaultsToCard() {
        XCTAssertEqual(Account(name: "Cash").resolvedSymbol, Account.defaultSymbol)
        XCTAssertEqual(Account(name: "GoPay", iconName: "wallet.pass.fill").resolvedSymbol,
                       "wallet.pass.fill")
    }

    // MARK: - Per-type auto glyph

    func testAutoSymbolIsTypeAppropriate() {
        // Category infers from the name; Account is always the card default.
        XCTAssertEqual(Category.autoSymbol(forName: "Transport"), "car.fill")
        XCTAssertEqual(Account.autoSymbol(forName: "Transport"), Account.defaultSymbol)
    }

    // MARK: - Hex / HSB helpers

    func testHexRGBParsing() throws {
        XCTAssertNil(HexColor.rgb("nope"))
        XCTAssertNil(HexColor.rgb("12345"))       // wrong length
        let white = try XCTUnwrap(HexColor.rgb("#FFFFFF"))
        XCTAssertEqual(white.r, 1, accuracy: 0.001)
        XCTAssertEqual(white.g, 1, accuracy: 0.001)
        XCTAssertEqual(white.b, 1, accuracy: 0.001)
    }

    /// A hue authored to hex and read back recovers (approximately) the same hue —
    /// this is what lets a stored swatch rebuild its dark-mode tone.
    func testHueRoundTripsThroughHex() {
        for hue in AppearancePalette.hues {
            let hex = HexColor.hexString(hue: hue, saturation: 0.28, brightness: 0.96)
            guard let recovered = HexColor.hue(hex) else {
                return XCTFail("no hue recovered from \(hex)")
            }
            // Allow a small quantisation drift from the 8-bit round trip.
            XCTAssertEqual(recovered, hue, accuracy: 0.02, "hue \(hue) via \(hex)")
        }
    }

    // MARK: - Palette integrity

    func testPaletteSwatchesAreValidAndAligned() {
        XCTAssertEqual(AppearancePalette.swatches.count, AppearancePalette.hues.count)
        for hex in AppearancePalette.swatches {
            XCTAssertNotNil(HexColor.rgb(hex), "unparseable swatch \(hex)")
        }
    }
}
