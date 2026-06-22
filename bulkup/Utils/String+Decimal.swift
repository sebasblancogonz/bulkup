import Foundation

extension String {
    /// Parses a decimal that may use the locale comma separator (the Spanish
    /// number pad shows "," while `Double(_:)` only accepts "."). Returns nil if
    /// the string isn't a valid number.
    var decimalValue: Double? {
        Double(replacingOccurrences(of: ",", with: "."))
    }
}
