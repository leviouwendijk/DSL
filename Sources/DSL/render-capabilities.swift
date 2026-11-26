/// What a render target can show. Renderers declare theirs and degrade the
/// semantic cases through the shared rules below, so every target that lacks
/// a capability falls back the same way.
public struct RenderCapabilities:
    Sendable,
    Codable,
    Hashable
{
    public enum ColorDepth:
        Int,
        Sendable,
        Codable,
        Hashable,
        Comparable
    {
        case none
        /// The 16 standard terminal colours.
        case basic
        /// 256 indexed colours.
        case indexed
        /// 24-bit colour.
        case trueColor

        public static func < (
            lhs: Self,
            rhs: Self
        ) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Link text can carry its URL invisibly (`<a>`, Markdown links, OSC 8).
    public var hyperlinks: Bool
    public var images: Bool
    /// Tables keep their columns; without, rows are shown as fields.
    public var tables: Bool
    public var colorDepth: ColorDepth
    /// Scripts run (islands, toggles).
    public var interactivity: Bool

    public init(
        hyperlinks: Bool,
        images: Bool,
        tables: Bool,
        colorDepth: ColorDepth,
        interactivity: Bool
    ) {
        self.hyperlinks = hyperlinks
        self.images = images
        self.tables = tables
        self.colorDepth = colorDepth
        self.interactivity = interactivity
    }

    /// Unstyled text: nothing but words and line breaks.
    public static var plainText: Self {
        .init(
            hyperlinks: false,
            images: false,
            tables: false,
            colorDepth: .none,
            interactivity: false
        )
    }

    public static var markdown: Self {
        .init(
            hyperlinks: true,
            images: true,
            tables: true,
            colorDepth: .none,
            interactivity: false
        )
    }

    /// A static page: no scripts.
    public static var staticHTML: Self {
        .init(
            hyperlinks: true,
            images: true,
            tables: true,
            colorDepth: .trueColor,
            interactivity: false
        )
    }
}

public extension RenderCapabilities {
    enum LinkForm:
        Sendable,
        Hashable
    {
        /// The text, linked to `url`.
        case hyperlink(url: String)
        /// The text, then the URL in visible form.
        case textWithURL(url: String)
        case text
    }

    enum ImageForm:
        Sendable,
        Hashable
    {
        case image(url: String)
        /// The alt text, linked to the image.
        case link(url: String)
        case alt
    }

    /// A link without a URL is its text. Without hyperlinks, an in-document
    /// anchor is dropped (it means nothing printed) and a URL that the text
    /// already spells out isn't repeated.
    func link(
        _ target: StructuredContent.LinkTarget,
        content: [StructuredContent.Inline],
        resolver: some StructuredContentURLResolving
    ) -> LinkForm {
        guard let url = resolver.url(target) else {
            return .text
        }

        if hyperlinks {
            return .hyperlink(url: url)
        }

        if case .anchor = target {
            return .text
        }

        let text = content.map(\.plainText).joined()
        return text == url ? .text : .textWithURL(url: url)
    }

    /// An image without a URL, or on a target without images or links, is
    /// its alt text.
    func image(
        _ source: StructuredContent.ImageSource,
        resolver: some StructuredContentURLResolving
    ) -> ImageForm {
        guard let url = resolver.url(source) else {
            return .alt
        }

        if images {
            return .image(url: url)
        }

        return hyperlinks ? .link(url: url) : .alt
    }
}
