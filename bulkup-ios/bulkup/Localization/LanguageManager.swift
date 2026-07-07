import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case spanish = "es"
    case english = "en"

    var id: String { rawValue }

    /// .lproj code to install, or nil to follow the device.
    var localeCode: String? {
        switch self {
        case .system: return nil
        case .spanish: return "es"
        case .english: return "en"
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    private let storageKey = "app_language"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: storageKey)
            Bundle.setLanguage(language.localeCode)
        }
    }

    /// Locale for SwiftUI's environment (drives Text + formatters).
    var locale: Locale {
        if let code = language.localeCode { return Locale(identifier: code) }
        return Locale(identifier: Locale.preferredLanguages.first ?? "es")
    }

    /// Effective language code ("en"/"es") to send when importing plans, so the
    /// backend can translate the parsed plan to the language the user sees.
    /// Source plans are Spanish, so anything that isn't English maps to "es".
    var resolvedCode: String {
        switch language {
        case .english: return "en"
        case .spanish: return "es"
        case .system:
            let device = (Locale.preferredLanguages.first ?? "es").prefix(2).lowercased()
            return device == "en" ? "en" : "es"
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        let initial = AppLanguage(rawValue: stored ?? AppLanguage.system.rawValue) ?? .system
        self.language = initial
        Bundle.setLanguage(initial.localeCode)
    }

#if DEBUG
    /// Asserts the localization infra is wired: both lproj bundles exist and the
    /// English override actually changes a known string. Call once at launch.
    static func runSelfCheck() {
        guard
            let esPath = Bundle.main.path(forResource: "es", ofType: "lproj"),
            let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let esBundle = Bundle(path: esPath),
            let enBundle = Bundle(path: enPath)
        else {
            assertionFailure("i18n: es/en .lproj not found — catalog or knownRegions misconfigured")
            return
        }
        let es = esBundle.localizedString(forKey: "Ajustes", value: nil, table: nil)
        let en = enBundle.localizedString(forKey: "Ajustes", value: nil, table: nil)
        assert(es == "Ajustes", "i18n: Spanish source string changed unexpectedly (got \(es))")
        assert(en == "Settings", "i18n: English translation missing/incorrect (got \(en))")
    }
#endif
}
