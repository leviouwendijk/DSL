public enum ScopeSelection: Sendable, Equatable {
    case all
    case scoped(ScopeIdentifier)
    case unscoped
    case excluding(Set<ScopeIdentifier>)
}

public extension ScopeSelection {
    static func scoped<Scope: ScopeIdentifying>(
        _ scope: Scope
    ) -> Self {
        .scoped(scope.scope)
    }

    static func excluding<Scope: ScopeIdentifying>(
        _ scopes: [Scope]
    ) -> Self {
        .excluding(
            Set(scopes.map(\.scope))
        )
    }

    func includes(
        scope: ScopeIdentifier
    ) -> Bool {
        switch self {
        case .all:
            return true

        case .scoped(let selected):
            return selected == scope

        case .unscoped:
            return false

        case .excluding(let excluded):
            return !excluded.contains(scope)
        }
    }
}
