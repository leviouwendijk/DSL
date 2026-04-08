public protocol ScopeIdentifying: Sendable {
    var scope: ScopeIdentifier { get }
}

public extension ScopeIdentifying where Self: RawRepresentable, Self.RawValue == String {
    var scope: ScopeIdentifier {
        ScopeIdentifier(rawValue)
    }
}
