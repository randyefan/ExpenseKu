import Foundation

nonisolated extension AppLanguage {
    var title: String {
        switch self {
        case .system: AppLocalization.string(.followDeviceLanguage)
        case .indonesian: "Bahasa Indonesia"
        case .english: "English"
        }
    }
}
