public indirect enum StructuredContent:
    Sendable,
    Codable,
    Hashable
{
    public struct Role:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable,
        ExpressibleByStringLiteral
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }

        public init(
            stringLiteral value: String
        ) {
            self.init(
                rawValue: value
            )
        }
    }

    public enum ListStyle:
        Sendable,
        Codable,
        Hashable
    {
        case unordered
        case ordered
    }

    public indirect enum Inline:
        Sendable,
        Codable,
        Hashable
    {
        case text(String)
        case code(String)
        case emphasis([Inline])
        case strong([Inline])
        case link(
            target: LinkTarget,
            content: [Inline]
        )
        case citation(
            key: CitationKey,
            locators: [ReferenceLocator]
        )
        case footnote(StructuredContent)
        /// A numbered mark pointing at a note: what enumeration lowers a
        /// citation or footnote occurrence to.
        case noteReference(
            number: Int,
            anchor: AnchorKey
        )
    }

    case collection([StructuredContent])

    case paragraph([Inline])

    case code(
        language: String?,
        source: String
    )

    /// Quoted content, with the source it is attributed to.
    case quote(
        StructuredContent,
        attribution: [Inline]? = nil
    )

    case list(
        style: ListStyle,
        items: [StructuredContent]
    )

    case group(
        role: Role?,
        title: [Inline]?,
        content: StructuredContent
    )

    /// Rows of cells under a header row, read column by column.
    case table(
        header: [StructuredContent],
        rows: [[StructuredContent]]
    )

    case heading(
        level: Int,
        anchor: AnchorKey?,
        content: [Inline]
    )

    case image(
        source: ImageSource,
        alt: String
    )

    /// Content with a caption, numbered by the figure enumeration.
    case figure(
        anchor: AnchorKey?,
        content: StructuredContent,
        caption: [Inline]?
    )

    /// Lines kept as written: breaks and leading spaces are content.
    case verse([[Inline]])

    /// A section break inside running text.
    case rule

    case definitions([Definition])

    case listing(Listing)

    /// Numbered notes (footnotes, bibliography entries): what enumeration
    /// lowers a footnote or bibliography listing to.
    case notes([Note])

    /// A construct only `target` can render; every other target renders
    /// `fallback`.
    case native(
        target: NativeTarget,
        key: NativeKey,
        fallback: StructuredContent
    )
}

public protocol StructuredContentRoleProviding:
    Sendable
{
    var structuredContentRole: StructuredContent.Role { get }
}

public extension StructuredContentRoleProviding
where
    Self: RawRepresentable,
    Self.RawValue == String
{
    var structuredContentRole: StructuredContent.Role {
        .init(
            rawValue: rawValue
        )
    }
}
