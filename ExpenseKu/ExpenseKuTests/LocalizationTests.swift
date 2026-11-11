import Foundation
import SwiftData
import XCTest
@testable import ExpenseKu

nonisolated final class LocalizationTests: XCTestCase {
    func testApprovedTermsInBothLanguages() {
        let labels: [(LocalizedStringResource, String, String)] = [
            (.expenses, "Expenses", "Pengeluaran"),
            (.insights, "Insights", "Analisis"),
            (.manage, "Manage", "Kelola"),
            (.account, "Account", "Sumber dana"),
            (.envelopeKind, "Envelope", "Pos anggaran"),
            (.funded, "Funded", "Dana siap"),
            (.paymentDone, "Done", "Sudah dibayar"),
            (.done, "Done", "Selesai"),
            (.setAsideFunds, "Set aside", "Dana sisihan"),
            (.ownerName, "Me", "Saya"),
            (.remainingFunds, "Remaining", "Sisa")
        ]

        for (resource, english, indonesian) in labels {
            XCTAssertEqual(localized(resource, language: "en"), english)
            XCTAssertEqual(localized(resource, language: "id"), indonesian)
        }
    }

    func testCountsUseEachLanguagesPluralRules() {
        for count in [0, 1, 2, 14] {
            XCTAssertEqual(localized(.planItemCount(count), language: "en"), "\(count) \(count == 1 ? "item" : "items")")
            XCTAssertEqual(localized(.planItemCount(count), language: "id"), "\(count) item")
            XCTAssertEqual(localized(.planEnvelopeCount(count), language: "id"), "\(count) pos anggaran")
            XCTAssertEqual(localized(.planIncomeCount(count), language: "id"), "\(count) pemasukan")
            XCTAssertEqual(localized(.planExpenseCount(count), language: "id"), "\(count) pengeluaran")
        }
        XCTAssertEqual(localized(.planCategoryCount(1), language: "en"), "1 category")
        XCTAssertEqual(localized(.planCategoryCount(2), language: "en"), "2 categories")
        XCTAssertEqual(localized(.personCount(2), language: "en"), "2 people")
    }

    func testCountsAfterStringArgumentsStillSelectTheRightPlural() {
        XCTAssertEqual(localized(.entityExpenseCount("Category", 1, "All time"), language: "en"),
                       "Category · 1 expense · All time")
        XCTAssertEqual(localized(.entityExpenseCount("Category", 2, "All time"), language: "en"),
                       "Category · 2 expenses · All time")
        XCTAssertEqual(localized(.entityExpenseCount("Kategori", 2, "Sepanjang waktu"), language: "id"),
                       "Kategori · 2 pengeluaran · Sepanjang waktu")
    }

    func testDestructiveConfirmationsKeepTheirMeaningInBothLanguages() {
        XCTAssertEqual(localized(.planAssignedExpensesKept(1), language: "en"),
                       "1 expense assigned to it stays in your ledger and goes back to counting by category.")
        XCTAssertEqual(localized(.planAssignedExpensesKept(2), language: "en"),
                       "2 expenses assigned to it stay in your ledger and go back to counting by category.")
        XCTAssertEqual(localized(.planAssignedExpensesKept(2), language: "id"),
                       "2 pengeluaran yang dimasukkan tetap disimpan dan kembali dihitung berdasarkan kategori.")
        XCTAssertEqual(localized(.planSetAsidesLoseEnvelope(2, " pada Oktober"), language: "id"),
                       "2 dana sisihan pada Oktober akan kehilangan pos anggarannya.")
        XCTAssertEqual(localized(.expensesAreKept, language: "id"), "Pengeluaran tetap disimpan.")
    }

    func testInterpolatedUserNamesStayUnchanged() {
        let name = "Jago & Dana Liburan"
        XCTAssertEqual(localized(.movedTo(name), language: "id"), "Dipindahkan ke \(name)")
        XCTAssertEqual(localized(.movedTo(name), language: "en"), "Moved to \(name)")
    }

    func testIndonesianSearchUsesWholeSentences() {
        XCTAssertEqual(localized(.emptySearchQuery("kopi"), language: "id"), "Tidak ada hasil untuk “kopi”.")
        XCTAssertEqual(localized(.emptySearchCategoryPeriod("kopi", "Makan", "Bulan ini"), language: "id"),
                       "Tidak ada hasil untuk “kopi” dalam kategori Makan selama Bulan ini.")
    }

    func testAppAndShareExtensionContainBothLanguagesForEveryKey() throws {
        let app = Bundle(for: Person.self)
        let plugins = try XCTUnwrap(app.builtInPlugInsURL)
        let share = try XCTUnwrap(Bundle(url: plugins.appending(path: "ExpenseKuShare.appex")))

        for bundle in [app, share] {
            let english = try bundledKeys(bundle, language: "en")
            let indonesian = try bundledKeys(bundle, language: "id")
            XCTAssertFalse(english.isEmpty)
            XCTAssertEqual(english, indonesian, bundle.bundleURL.lastPathComponent)
        }
    }

    func testCurrencyStaysIDRWhileNumberSeparatorsFollowTheLocale() {
        let amount = Decimal(1_234_567)
        let indonesian = amount.formattedIDR(locale: Locale(identifier: "id_ID"))
        let english = amount.formattedIDR(locale: Locale(identifier: "en_US"))
        XCTAssertTrue(indonesian.contains("Rp"))
        XCTAssertTrue(indonesian.contains("1.234.567"))
        XCTAssertFalse(indonesian.contains(",00"))
        XCTAssertTrue(english.contains("IDR"))
        XCTAssertTrue(english.contains("1,234,567"))
        XCTAssertFalse(english.contains(".00"))
    }

    func testCalendarMonthsAndRangesFollowTheLocale() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "id_ID")
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let cycle = PayCycle.containing(day, payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.title(calendar: calendar, locale: Locale(identifier: "id_ID")), "Agustus 2026")
        XCTAssertEqual(cycle.rangeText(calendar: calendar, locale: Locale(identifier: "id_ID")), "25/07/2026 ~ 24/08/2026")
        calendar.locale = Locale(identifier: "en_US")
        XCTAssertEqual(cycle.title(calendar: calendar, locale: Locale(identifier: "en_US")), "August 2026")
        XCTAssertEqual(cycle.rangeText(calendar: calendar, locale: Locale(identifier: "en_US")), "07/25/2026 ~ 08/24/2026")
    }

    @MainActor
    func testOwnerDisplayNameDoesNotRenameStoredPeople() {
        let owner = Person(name: Person.meName, isMe: true)
        let userNamedMe = Person(name: "Me")
        XCTAssertEqual(owner.displayName, String(localized: .ownerName))
        XCTAssertEqual(owner.name, "Me")
        XCTAssertEqual(userNamedMe.displayName, "Me")
        XCTAssertFalse(userNamedMe.isMe)
    }

    @MainActor
    func testSearchFindsTheOwnerByTheirDisplayedName() {
        let owner = Person(name: Person.meName, isMe: true)
        let expense = Expense(amount: 10_000, people: [owner])
        let tokens = ExpenseSearchMatch.tokens(owner.displayName)
        XCTAssertTrue(ExpenseSearchMatch.matches(expense, tokens: tokens))
        XCTAssertEqual(owner.name, "Me")
    }

    private func bundledKeys(_ bundle: Bundle, language: String) throws -> Set<String> {
        let directory = bundle.bundleURL.appending(path: "\(language).lproj", directoryHint: .isDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        var keys: Set<String> = []
        for suffix in ["strings", "stringsdict"] {
            let url = directory.appending(path: "Localizable.\(suffix)")
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
            let strings = try XCTUnwrap(plist as? [String: Any])
            keys.formUnion(strings.keys)
        }
        return keys
    }

    private func localized(_ resource: LocalizedStringResource, language: String) -> String {
        var resource = resource
        resource.locale = Locale(identifier: language)
        return String(localized: resource)
    }
}
