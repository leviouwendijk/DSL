public struct StructuredContent:
    Sendable,
    Hashable
{
    public struct Role:
        RawRepresentable,
        Sendable,
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
        Hashable
    {
        case unordered
        case ordered
    }

    public indirect enum Inline:
        Sendable,
        Hashable
    {
        case text(String)
        case code(String)
        case emphasis([Inline])
        case strong([Inline])
    }

    public indirect enum Block:
        Sendable,
        Hashable
    {
        case paragraph([Inline])

        case code(
            language: String?,
            source: String
        )

        case quote([Block])

        case list(
            style: ListStyle,
            items: [[Block]]
        )

        case group(
            role: Role?,
            title: [Inline]?,
            content: [Block]
        )
    }

    public let blocks: [Block]

    public init(
        blocks: [Block] = []
    ) {
        self.blocks = blocks
    }
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
