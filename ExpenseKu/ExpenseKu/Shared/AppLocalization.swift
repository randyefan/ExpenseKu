import Foundation

nonisolated enum AppLocalization {
    static var locale: Locale { LanguageSettings.shared.locale }

    static func string(_ resource: LocalizedStringResource, locale: Locale = Self.locale) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }
}
