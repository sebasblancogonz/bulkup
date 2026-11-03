//
//  NumberFormat.swift
//  bulkup
//
//  Locale-aware numbers for the UI ("85,2" in es, "85.2" in en).
//

import Foundation

@MainActor
enum BulkUpFormat {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        return f
    }()

    /// A measurement with at most `fraction` decimals and no trailing zeros.
    static func decimal(_ value: Double, fraction: Int = 1) -> String {
        let f = formatter
        f.locale = LanguageManager.shared.locale
        f.maximumFractionDigits = fraction
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(fraction)f", value)
    }

    /// "+0,6" / "−0,4" / "0" — a signed delta for a caption.
    static func signed(_ value: Double, fraction: Int = 1) -> String {
        let magnitude = decimal(abs(value), fraction: fraction)
        if abs(value) < pow(10, -Double(fraction)) / 2 { return "0" }
        return (value > 0 ? "+" : "−") + magnitude
    }
}
