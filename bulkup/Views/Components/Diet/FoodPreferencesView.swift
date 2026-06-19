import SwiftUI

enum FoodTagInput {
    static let maxPerList = 50

    /// Trims, rejects empties/case-insensitive dups, respects the cap. Returns the (possibly unchanged) list.
    static func add(_ raw: String, to list: [String]) -> [String] {
        let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, list.count < maxPerList,
              !list.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame })
        else { return list }
        return list + [tag]
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(add("  Nuez  ", to: []) == ["Nuez"], "trims whitespace")
        assert(add("nuez", to: ["Nuez"]) == ["Nuez"], "case-insensitive dedupe")
        assert(add("", to: ["Nuez"]) == ["Nuez"], "ignores empty")
        let full = (0..<maxPerList).map { "\($0)" }
        assert(add("new", to: full).count == maxPerList, "respects cap")
    }
    #endif
}
