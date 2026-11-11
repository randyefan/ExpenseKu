import Foundation
import Observation
import Synchronization

@Observable
nonisolated final class LanguageSettings: Sendable {
    static let preferenceKey = "appLanguage"
    static let shared = LanguageSettings(suiteName: ReceiptInboxFolder.appGroup)

    private let storage: Mutex<AppLanguage>
    private let suiteName: String

    init(suiteName: String) {
        self.suiteName = suiteName
        storage = Mutex(Self.savedLanguage(in: UserDefaults(suiteName: suiteName) ?? .standard))
    }

    var language: AppLanguage {
        access(keyPath: \.language)
        return storage.withLock { $0 }
    }

    var locale: Locale { language.locale() }

    @MainActor
    func select(_ language: AppLanguage) {
        guard self.language != language else { return }
        withMutation(keyPath: \.language) {
            storage.withLock {
                $0 = language
            }
            defaults.set(language.rawValue, forKey: Self.preferenceKey)
        }
    }

    @MainActor
    func refresh() {
        withMutation(keyPath: \.language) {
            let saved = Self.savedLanguage(in: defaults)
            storage.withLock { $0 = saved }
        }
    }

    private static func savedLanguage(in defaults: UserDefaults) -> AppLanguage {
        defaults.string(forKey: preferenceKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    private var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }
}
