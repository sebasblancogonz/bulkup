import Foundation
import ObjectiveC

private var associatedLanguageBundleKey: UInt8 = 0

/// When installed on Bundle.main, routes localized-string lookups to the
/// selected .lproj bundle so the in-app language override is respected.
///
/// IMPORTANT: this only intercepts `localizedString(forKey:value:table:)`, which
/// `NSLocalizedString` and `Text(LocalizedStringKey)` go through. `String(localized:)`
/// (the iOS 15 API) resolves via a different path that BYPASSES this override, so
/// it does NOT follow the in-app switch — use `NSLocalizedString` for runtime
/// strings instead. See memory: i18n-live-language-switch.
final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let override = objc_getAssociatedObject(self, &associatedLanguageBundleKey) as? Bundle {
            return override.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    private static let installOverrideOnce: Void = {
        object_setClass(Bundle.main, LocalizedBundle.self)
    }()

    /// Install a language code's .lproj as the active localization.
    /// Pass nil to follow the system default.
    static func setLanguage(_ language: String?) {
        _ = installOverrideOnce
        var override: Bundle?
        if let language,
           let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            override = langBundle
        }
        objc_setAssociatedObject(
            Bundle.main, &associatedLanguageBundleKey, override, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
