/// Symbols carried by `StructuredContent`.
///
/// The content model stores keys, never the values they name: the reference
/// library, the asset manifest and the route table are the symbol tables, and
/// a resolution pass maps keys to numbers, URLs and files. Typed authoring
/// APIs lower to these keys, so keys don't take string literals.
public extension StructuredContent {
    /// A bibliographic reference, by its public identifier.
    struct CitationKey:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    /// An asset in a manifest.
    struct AssetKey:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    /// A page in a route table.
    struct PageKey:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    /// A position inside a document.
    struct AnchorKey:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    /// A construct that only one target can render, looked up by that
    /// target's renderer.
    struct NativeKey:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }

    /// The target a native construct belongs to.
    struct NativeTarget:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }

        public static var html: Self {
            .init(
                rawValue: "html"
            )
        }
    }

    enum LinkTarget:
        Sendable,
        Codable,
        Hashable
    {
        case page(
            PageKey,
            anchor: AnchorKey?
        )
        case anchor(AnchorKey)
        case asset(AssetKey)
        case external(String)
    }

    /// Where an image comes from: an asset in a manifest, or a URL the
    /// source already names (Markdown, imported content).
    enum ImageSource:
        Sendable,
        Codable,
        Hashable
    {
        case asset(AssetKey)
        case external(String)
    }

    struct Definition:
        Sendable,
        Codable,
        Hashable
    {
        public let term: [Inline]
        public let description: StructuredContent

        public init(
            term: [Inline],
            description: StructuredContent
        ) {
            self.term = term
            self.description = description
        }
    }

    /// A footnote or bibliography entry, with the occurrence numbers that
    /// point at it.
    struct Note:
        Sendable,
        Codable,
        Hashable
    {
        /// Where `noteReference`s link to.
        public let anchor: AnchorKey
        public let pointers: [Int]
        public let content: StructuredContent
        /// Occurrences that named a locator, grouped by locator set.
        public let uses: [NoteUse]

        public init(
            anchor: AnchorKey,
            pointers: [Int],
            content: StructuredContent,
            uses: [NoteUse] = []
        ) {
            self.anchor = anchor
            self.pointers = pointers
            self.content = content
            self.uses = uses
        }

        /// `[1, 4]`.
        public var label: String {
            "[" + pointers.map(String.init).joined(separator: ", ") + "]"
        }
    }

    struct NoteUse:
        Sendable,
        Codable,
        Hashable
    {
        public let pointers: [Int]
        public let locators: [ReferenceLocator]

        public init(
            pointers: [Int],
            locators: [ReferenceLocator]
        ) {
            self.pointers = pointers
            self.locators = locators
        }

        /// `p. 12 [2, 5]`.
        public var rendered: String {
            locators.map(\.rendered).joined(separator: ", ")
                + " [" + pointers.map(String.init).joined(separator: ", ") + "]"
        }
    }

    /// Where a document enumeration prints its list.
    enum Listing:
        Sendable,
        Codable,
        Hashable
    {
        case bibliography
        case footnotes
        case contents
    }
}

public extension StructuredContent.Role {
    static var note: Self {
        .init(
            rawValue: "note"
        )
    }

    static var tip: Self {
        .init(
            rawValue: "tip"
        )
    }

    static var warning: Self {
        .init(
            rawValue: "warning"
        )
    }

    static var caution: Self {
        .init(
            rawValue: "caution"
        )
    }

    /// A quotation that opens a piece or a section.
    static var epigraph: Self {
        .init(
            rawValue: "epigraph"
        )
    }
}
