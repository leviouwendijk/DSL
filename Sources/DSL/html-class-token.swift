public enum HTMLClassToken:
    Sendable,
    Hashable
{
    case semantic(AnyHTMLClass)
    case raw(String)

    public init(
        _ value: AnyHTMLClass
    ) {
        self = .semantic(value)
    }

    public var rawValue: String {
        switch self {
        case .semantic(let value):
            return value.rawValue
        case .raw(let value):
            return value
        }
    }

    public var semanticValue: AnyHTMLClass? {
        switch self {
        case .semantic(let value):
            return value
        case .raw:
            return nil
        }
    }
}

public extension AnyHTMLClass {
    var token: HTMLClassToken {
        .semantic(self)
    }
}

public extension HTMLClass {
    var token: HTMLClassToken {
        .semantic(erased)
    }
}
