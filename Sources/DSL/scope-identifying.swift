public protocol ScopeIdentifying: Sendable {
    var scope_id: ScopeIdentifier { get }
}

public extension ScopeIdentifying where Self: RawRepresentable, Self.RawValue == String {
    var scope_id: ScopeIdentifier {
        ScopeIdentifier(rawValue)
    }
}
