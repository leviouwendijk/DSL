public indirect enum StructuredContent:
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

    case collection([StructuredContent])

    case paragraph([Inline])

    case code(
        language: String?,
        source: String
    )

    case quote(StructuredContent)

    case list(
        style: ListStyle,
        items: [StructuredContent]
    )

    case group(
        role: Role?,
        title: [Inline]?,
        content: StructuredContent
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
