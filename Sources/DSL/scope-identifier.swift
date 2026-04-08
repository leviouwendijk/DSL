public struct ScopeIdentifier: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(value)
    }
}
