import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case indonesian = "id"
    case english = "en"

    var id: String { rawValue }

    func locale(systemLocale: Locale = .current, preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        let code: String
        switch self {
        case .system:
            code = Bundle.preferredLocalizations(from: ["en", "id"], forPreferences: preferredLanguages).first ?? "en"
        case .indonesian, .english:
            code = rawValue
        }
        var components = Locale.Components(identifier: systemLocale.identifier)
        components.region = systemLocale.region
        components.languageComponents = Locale.Language.Components(languageCode: .init(code))
        return Locale(components: components)
    }
}
