//
//  BankLogoTests.swift
//  ExpenseKuTests
//
//  docs/prd/bank-logos.md, one test per rule, against the eight-bank snapshot the
//  PRD names in §6.3.
//

import XCTest
@testable import ExpenseKu

nonisolated private func logo(_ id: String, _ name: String, order: Int, modified: Date? = nil) -> BankLogo {
    BankLogo(id: id, displayName: name, tintHex: "0060AF", sortOrder: order, modified: modified)
}

nonisolated private struct FakeSource: BankLogoSource {
    var logos: [BankLogo]
    var failsCatalog = false
    var missingImages: Set<String> = []
    let imageDirectory: URL

    func fetchCatalog() async throws -> [RemoteBankLogo] {
        if failsCatalog { throw URLError(.notConnectedToInternet) }
        return logos.map { RemoteBankLogo(logo: $0, recordName: $0.id) }
    }

    func fetchImage(recordName: String) async throws -> URL? {
        guard !missingImages.contains(recordName) else { return nil }
        let url = imageDirectory.appending(path: "\(recordName)-\(UUID().uuidString).png")
        try Data(recordName.utf8).write(to: url)
        return url
    }
}

nonisolated final class BankLogoTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "BankLogoTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - §4 Picking

    /// **Logos are ordered by sortOrder, then displayName**, one entry per id.
    func testTheBanksSectionFollowsSortOrderThenName() {
        let ordered = BankLogoRules.ordered([
            logo("bni", "BNI", order: 30), logo("bca", "BCA", order: 10),
            logo("bri", "BRI", order: 30), logo("bca", "BCA again", order: 5),
        ])
        XCTAssertEqual(ordered.map(\.displayName), ["BCA again", "BNI", "BRI"])
    }

    /// The first snapshot is the PRD's eight banks, in that order.
    func testTheSnapshotIsTheEightBanksInOrder() {
        XCTAssertEqual(BankLogoRules.ordered(BankLogo.snapshot).map(\.id),
                       ["bca", "bri", "bni", "mandiri", "bsi", "jago", "seabank", "cimb-niaga"])
    }

    /// **Search matches a logo's displayName**: "bca" leaves BCA only.
    func testSearchMatchesTheDisplayName() {
        XCTAssertEqual(BankLogoRules.matching(BankLogo.snapshot, query: "bca").map(\.id), ["bca"])
        XCTAssertEqual(BankLogoRules.matching(BankLogo.snapshot, query: " Jago ").map(\.id), ["jago"])
        XCTAssertEqual(BankLogoRules.matching(BankLogo.snapshot, query: "").count, 8)
        XCTAssertTrue(BankLogoRules.matching(BankLogo.snapshot, query: "kopi").isEmpty)
    }

    /// An id that cannot be a file name is dropped, as is a logo with no name.
    func testOnlySlugIDsAreUsable() {
        XCTAssertTrue(BankLogoRules.isUsable(logo("cimb-niaga", "CIMB Niaga", order: 1)))
        XCTAssertFalse(BankLogoRules.isUsable(logo("../bca", "BCA", order: 1)))
        XCTAssertFalse(BankLogoRules.isUsable(logo("BCA", "BCA", order: 1)))
        XCTAssertFalse(BankLogoRules.isUsable(logo("bca", " ", order: 1)))
    }

    // MARK: - §5.3 Resolution

    /// **A resolving brand draws its logo; its chips draw the bank glyph.**
    func testABrandInTheCatalogDrawsItsLogo() {
        let bca = logo("bca", "BCA", order: 10)
        XCTAssertEqual(AccountAppearance.mark(brandID: "bca", symbol: "creditcard.fill", logo: bca), .logo(bca))
        XCTAssertEqual(AccountAppearance.chipSymbol(brandID: "bca", symbol: "creditcard.fill"), "building.columns.fill")
    }

    /// **A withdrawn brand draws the bank glyph**, in mark and chip alike.
    func testAWithdrawnBrandDrawsTheBankGlyph() {
        XCTAssertEqual(AccountAppearance.mark(brandID: "mandiri", symbol: "creditcard.fill", logo: nil),
                       .symbol("building.columns.fill"))
        XCTAssertEqual(AccountAppearance.chipSymbol(brandID: "mandiri", symbol: "creditcard.fill"),
                       "building.columns.fill")
    }

    /// **No brand: the owner's symbol, or the card glyph** — exactly as before.
    func testNoBrandKeepsTheSymbol() {
        XCTAssertEqual(AccountAppearance.mark(brandID: nil, symbol: "wallet.pass.fill", logo: nil),
                       .symbol("wallet.pass.fill"))
        XCTAssertEqual(AccountAppearance.chipSymbol(brandID: nil, symbol: "wallet.pass.fill"), "wallet.pass.fill")
    }

    // MARK: - §5.4 Colour

    /// **The owner's colour wins; Auto takes the logo's tint through the pastel recipe;**
    /// with no logo, Auto stays with the name.
    func testColourPrecedence() throws {
        let bca = logo("bca", "BCA", order: 10)
        XCTAssertEqual(AccountAppearance.colorHex("F5C6A0", logo: bca), "F5C6A0")
        let brand = try XCTUnwrap(AccountAppearance.colorHex(nil, logo: bca))
        XCTAssertEqual(brand, AppearancePalette.hex(forHue: try XCTUnwrap(HexColor.hue("0060AF"))))
        XCTAssertNil(AccountAppearance.colorHex(nil, logo: nil))
    }

    // MARK: - §6.2 Sync

    /// **Only new or changed records download their image.**
    func testOnlyChangedImagesDownload() {
        let old = Date(timeIntervalSince1970: 1_000)
        let new = Date(timeIntervalSince1970: 2_000)
        let cached = [logo("bca", "BCA", order: 1, modified: old), logo("bri", "BRI", order: 2, modified: old)]
        let remote = [logo("bca", "BCA", order: 1, modified: old), logo("bri", "BRI", order: 2, modified: new),
                      logo("bni", "BNI", order: 3, modified: new)]
        XCTAssertEqual(BankLogoRules.idsToDownload(cached: cached, remote: remote), ["bri", "bni"])
    }

    /// **At most one fetch every ten minutes.**
    func testAFetchIsDueEveryTenMinutes() {
        let start = Date(timeIntervalSince1970: 0)
        XCTAssertTrue(BankLogoRules.isDue(lastAttempt: nil, now: start))
        XCTAssertFalse(BankLogoRules.isDue(lastAttempt: start, now: start.addingTimeInterval(599)))
        XCTAssertTrue(BankLogoRules.isDue(lastAttempt: start, now: start.addingTimeInterval(600)))
    }

    // MARK: - §6.3 Snapshot, §7 Lifetime

    /// **Never fetched: the bundled snapshot.**
    @MainActor
    func testANeverFetchedCatalogIsTheSnapshot() {
        let catalog = BankLogoCatalog(source: nil, store: BankLogoStore(directory: directory))
        XCTAssertFalse(catalog.isFetched)
        XCTAssertEqual(catalog.logos.count, 8)
        XCTAssertNotNil(catalog.logo(for: "mandiri"))
    }

    /// **Fetched once: the fetched catalog only** — a logo missing from it is withdrawn,
    /// and the snapshot no longer speaks for it, this launch or the next.
    @MainActor
    func testAFetchReplacesTheSnapshotAndWithdrawsWhatIsMissing() async {
        let store = BankLogoStore(directory: directory.appending(path: "store"))
        let modified = Date(timeIntervalSince1970: 1_000)
        let remote = BankLogo.snapshot.filter { $0.id != "mandiri" }.map { var l = $0; l.modified = modified; return l }
        let catalog = BankLogoCatalog(source: FakeSource(logos: remote, imageDirectory: directory), store: store)

        await catalog.refreshIfDue(now: .now)

        XCTAssertTrue(catalog.isFetched)
        XCTAssertNil(catalog.logo(for: "mandiri"))
        XCTAssertEqual(catalog.logos.count, 7)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.imageURL(for: "bca").path()))

        let relaunched = BankLogoCatalog(source: nil, store: store)
        XCTAssertTrue(relaunched.isFetched)
        XCTAssertNil(relaunched.logo(for: "mandiri"))
    }

    /// **A failed fetch keeps the last good catalog.**
    @MainActor
    func testAFailedFetchKeepsTheLastGoodCatalog() async {
        let source = FakeSource(logos: [], failsCatalog: true, imageDirectory: directory)
        let catalog = BankLogoCatalog(source: source, store: BankLogoStore(directory: directory.appending(path: "store")))

        await catalog.refreshIfDue(now: .now)

        XCTAssertFalse(catalog.isFetched)
        XCTAssertEqual(catalog.logos.count, 8)
    }

    /// A record with no image cannot be drawn, so it is left out rather than shown blank.
    @MainActor
    func testARecordWithNoImageIsLeftOut() async {
        let remote = [logo("bca", "BCA", order: 1, modified: .now), logo("bri", "BRI", order: 2, modified: .now)]
        let source = FakeSource(logos: remote, missingImages: ["bri"], imageDirectory: directory)
        let catalog = BankLogoCatalog(source: source, store: BankLogoStore(directory: directory.appending(path: "store")))

        await catalog.refreshIfDue(now: .now)

        XCTAssertEqual(catalog.logos.map(\.id), ["bca"])
    }

    /// **An empty catalog hides the Banks section**: nothing to list.
    @MainActor
    func testAnEmptyFetchLeavesNoLogos() async {
        let catalog = BankLogoCatalog(source: FakeSource(logos: [], imageDirectory: directory),
                                      store: BankLogoStore(directory: directory.appending(path: "store")))
        await catalog.refreshIfDue(now: .now)
        XCTAssertTrue(catalog.isFetched)
        XCTAssertTrue(catalog.logos.isEmpty)
    }

    /// A second refresh inside ten minutes does not reach the source.
    @MainActor
    func testARefreshInsideTheIntervalIsSkipped() async {
        let store = BankLogoStore(directory: directory.appending(path: "store"))
        let start = Date(timeIntervalSince1970: 10_000)
        let catalog = BankLogoCatalog(source: FakeSource(logos: [logo("bca", "BCA", order: 1, modified: start)],
                                                         imageDirectory: directory), store: store)
        await catalog.refreshIfDue(now: start)
        XCTAssertEqual(catalog.logos.map(\.id), ["bca"])

        try? FileManager.default.removeItem(at: store.imageURL(for: "bca"))
        await catalog.refreshIfDue(now: start.addingTimeInterval(60))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.imageURL(for: "bca").path()))
    }
}
