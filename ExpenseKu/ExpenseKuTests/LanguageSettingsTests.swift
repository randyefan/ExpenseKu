import Foundation
import Observation
import Synchronization
import XCTest
@testable import ExpenseKu

nonisolated final class LanguageSettingsTests: XCTestCase {
    @MainActor
    func testNewAndUnknownPreferencesFollowTheDevice() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(LanguageSettings(suiteName: suite).language, .system)
        defaults.set("unsupported", forKey: LanguageSettings.preferenceKey)
        XCTAssertEqual(LanguageSettings(suiteName: suite).language, .system)
    }

    @MainActor
    func testSelectionPersistsAcrossSettingsInstances() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        for language in [AppLanguage.indonesian, .english, .system] {
            settings.select(language)
            XCTAssertEqual(settings.language, language)
            XCTAssertEqual(LanguageSettings(suiteName: suite).language, language)
        }
    }

    func testDeviceSelectionMatchesSupportedPreferredLanguages() {
        let base = Locale(identifier: "en_US")
        XCTAssertEqual(AppLanguage.system.locale(systemLocale: base, preferredLanguages: ["id-ID", "en-US"]).language.languageCode?.identifier, "id")
        XCTAssertEqual(AppLanguage.system.locale(systemLocale: base, preferredLanguages: ["fr-FR", "en-GB"]).language.languageCode?.identifier, "en")
        XCTAssertEqual(AppLanguage.system.locale(systemLocale: base, preferredLanguages: ["fr-FR"]).language.languageCode?.identifier, "en")
    }

    func testExplicitLanguageKeepsTheDevicesRegionAndCalendar() {
        let base = Locale(identifier: "en_US@calendar=gregorian;hours=h23")
        for language in [AppLanguage.indonesian, .english] {
            let locale = language.locale(systemLocale: base, preferredLanguages: ["fr-FR"])
            XCTAssertEqual(locale.language.languageCode?.identifier, language.rawValue)
            XCTAssertEqual(locale.region, base.region)
            XCTAssertEqual(locale.calendar.identifier, base.calendar.identifier)
            XCTAssertEqual(locale.hourCycle, base.hourCycle)
        }
    }

    @MainActor
    func testAnExistingResourceResolvesInTheNewLanguageImmediately() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        let resource = LocalizedStringResource.categoryCount(2)
        settings.select(.english)
        XCTAssertEqual(AppLocalization.string(resource, locale: settings.locale), "2 categories")
        settings.select(.indonesian)
        XCTAssertEqual(AppLocalization.string(resource, locale: settings.locale), "2 kategori")
        settings.select(.english)
        XCTAssertEqual(AppLocalization.string(resource, locale: settings.locale), "2 categories")
    }

    @MainActor
    func testLocalizedReadsNotifySwiftUIObservationWhenTheChoiceChanges() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        let notified = Mutex(false)
        withObservationTracking {
            _ = AppLocalization.string(.manage, locale: settings.locale)
        } onChange: {
            notified.withLock { $0 = true }
        }
        settings.select(.indonesian)
        XCTAssertTrue(notified.withLock { $0 })
    }

    @MainActor
    func testSelectingTheSameLanguageDoesNotInvalidateViews() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        let notified = Mutex(false)
        withObservationTracking {
            _ = settings.language
        } onChange: {
            notified.withLock { $0 = true }
        }
        settings.select(.system)
        XCTAssertFalse(notified.withLock { $0 })
    }

    @MainActor
    func testRefreshingReadsThePreferenceSharedWithTheExtension() throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        defaults.set("id", forKey: LanguageSettings.preferenceKey)
        settings.refresh()
        XCTAssertEqual(settings.language, .indonesian)
    }

    @MainActor
    func testTheSelectedLocaleCanBeReadFromBackgroundDerivations() async throws {
        let suite = "LanguageSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = LanguageSettings(suiteName: suite)
        settings.select(.indonesian)
        let title = await Task.detached {
            AppLocalization.string(.manage, locale: settings.locale)
        }.value
        XCTAssertEqual(title, "Kelola")
    }

    @MainActor
    func testDerivedMessagesAndDatesDoNotKeepThePreviousLanguage() throws {
        let settings = LanguageSettings.shared
        let previous = settings.language
        defer { settings.select(previous) }
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let cycle = PayCycle.containing(date, payday: 1, calendar: calendar)
        settings.select(.english)
        let english = [EmptyNotice.filterTitle, EmptyNotice.filterPeriodMessage, FilterSheet.help,
                       LookBackCopy.uncategorized, LookBackCopy.categoriseFirst, LookBackCopy.dormantHere,
                       LookBackCopy.emptyTitle, LookBackCopy.addToEnvelope, PlanSections.unassignedName,
                       GroupShares.ungroupedName, EnvelopeOptions.byCategoryDetailForMany, EnvelopeOptions.noEnvelopeDetail,
                       AppearancePalette.groups[0].title]
        XCTAssertEqual(cycle.title(calendar: calendar), "August 2026")
        XCTAssertEqual(PlanCopy.counted(2, .envelope), "2 envelopes")
        settings.select(.indonesian)
        let indonesian = [EmptyNotice.filterTitle, EmptyNotice.filterPeriodMessage, FilterSheet.help,
                          LookBackCopy.uncategorized, LookBackCopy.categoriseFirst, LookBackCopy.dormantHere,
                          LookBackCopy.emptyTitle, LookBackCopy.addToEnvelope, PlanSections.unassignedName,
                          GroupShares.ungroupedName, EnvelopeOptions.byCategoryDetailForMany, EnvelopeOptions.noEnvelopeDetail,
                          AppearancePalette.groups[0].title]
        for (before, after) in zip(english, indonesian) { XCTAssertNotEqual(before, after) }
        XCTAssertEqual(cycle.title(calendar: calendar), "Agustus 2026")
        XCTAssertEqual(PlanCopy.counted(2, .envelope), "2 pos anggaran")
        XCTAssertEqual(Decimal(1_000).formattedIDR(), Decimal(1_000).formattedIDR(locale: settings.locale))
    }

    @MainActor
    func testChangingLanguagePreservesStoredNamesAndOwnerIdentity() {
        let settings = LanguageSettings.shared
        let previous = settings.language
        defer { settings.select(previous) }
        let owner = Person(name: Person.meName, isMe: true)
        let person = Person(name: "Me")
        settings.select(.english)
        XCTAssertEqual(owner.displayName, "Me")
        settings.select(.indonesian)
        XCTAssertEqual(owner.displayName, "Saya")
        XCTAssertEqual(owner.name, "Me")
        XCTAssertTrue(owner.isMe)
        XCTAssertEqual(person.displayName, "Me")
        XCTAssertFalse(person.isMe)
    }
}
