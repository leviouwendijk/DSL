/// Plain forms of the semantic cases, shared by renderers that can't (yet)
/// resolve symbols, so every target degrades the same way.
public enum StructuredContentFallback {
    /// `[key, p. 12]`, until a citation pass numbers it.
    public static func citation(
        key: StructuredContent.CitationKey,
        locators: [ReferenceLocator]
    ) -> String {
        let parts = [key.rawValue] + locators.map(\.rendered)
        return "[" + parts.joined(separator: ", ") + "]"
    }

    /// Heading levels outside 1...6 are clamped.
    public static func headingLevel(
        _ level: Int
    ) -> Int {
        min(
            6,
            max(
                1,
                level
            )
        )
    }
}

public extension StructuredContent.Inline {
    /// The text of an inline run without markup; citations use their
    /// fallback form and footnotes are left out.
    var plainText: String {
        switch self {
        case .text(let text),
             .code(let text):
            return text
        case .emphasis(let content),
             .strong(let content),
             .link(_, let content):
            return content.map(\.plainText).joined()
        case .citation(let key, let locators):
            return StructuredContentFallback.citation(
                key: key,
                locators: locators
            )
        case .footnote:
            return ""
        case .noteReference(let number, _):
            return "[\(number)]"
        }
    }
}

public extension StructuredContent {
    /// The words of a block on one line, for content that has to sit inline
    /// (footnotes, search text). Tables, definitions and listings are left out.
    var plainText: String {
        switch self {
        case .collection(let children):
            return children
                .map(\.plainText)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        case .paragraph(let inline),
             .heading(_, _, let inline):
            return inline.map(\.plainText).joined()
        case .quote(let inner, let attribution):
            let source = attribution.map {
                " — " + $0.map(\.plainText).joined()
            } ?? ""
            return inner.plainText + source
        case .group(_, _, let inner),
             .native(_, _, let inner):
            return inner.plainText
        case .figure(_, let content, let caption):
            return [
                content.plainText,
                caption.map { $0.map(\.plainText).joined() } ?? "",
            ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        case .verse(let lines):
            return lines
                .map { $0.map(\.plainText).joined() }
                .joined(separator: " / ")
        case .list(_, let items):
            return items.map(\.plainText).joined(separator: "; ")
        case .image(_, let alt):
            return alt
        case .code(_, let source):
            return source
        case .table,
             .definitions,
             .listing,
             .notes,
             .rule:
            return ""
        }
    }
}
