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

    /// The URL a link target has without a resolver: external URLs and
    /// in-document anchors. Pages and assets need a route table or manifest.
    public static func url(
        _ target: StructuredContent.LinkTarget
    ) -> String? {
        switch target {
        case .external(let url):
            return url
        case .anchor(let anchor):
            return "#" + anchor.rawValue
        case .page,
             .asset:
            return nil
        }
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
        }
    }
}
