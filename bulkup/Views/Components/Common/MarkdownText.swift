import SwiftUI

/// Minimal line-based markdown renderer for AI answers: headings (#/##/###),
/// bullet lists (- / *) and inline emphasis (**bold**, *italic*, `code`).
/// SwiftUI's native AttributedString(markdown:) only does inline, so block
/// elements (headings/lists) are handled per line here. ponytail: covers the
/// markdown the recipe model actually emits; swap in a full lib only if it grows.
struct MarkdownText: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
                lineView(raw.trimmingCharacters(in: .whitespaces))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func lineView(_ line: String) -> some View {
        if line.isEmpty {
            Color.clear.frame(height: 2)
        } else if let (level, text) = heading(line) {
            inline(text).font(headingFont(level))
        } else if let item = bullet(line) {
            HStack(alignment: .top, spacing: 6) {
                Text("•").foregroundColor(BulkUpColors.accent)
                inline(item)
            }
        } else {
            inline(line)
        }
    }

    private func inline(_ s: String) -> Text {
        if let attr = try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(s)
    }

    /// Returns (level 1-3, stripped text) for "# "/"## "/"###+ " prefixes.
    private func heading(_ line: String) -> (Int, String)? {
        for hashes in stride(from: 6, through: 1, by: -1) {
            let prefix = String(repeating: "#", count: hashes) + " "
            if line.hasPrefix(prefix) {
                return (min(hashes, 3), String(line.dropFirst(prefix.count)))
            }
        }
        return nil
    }

    private func bullet(_ line: String) -> String? {
        for p in ["- ", "* "] where line.hasPrefix(p) {
            return String(line.dropFirst(2))
        }
        return nil
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return BulkUpFont.sectionHeader()
        case 2: return BulkUpFont.cardTitle()
        default: return .system(size: 15, weight: .semibold)
        }
    }
}
