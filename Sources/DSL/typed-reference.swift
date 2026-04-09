public struct AnyHTMLClass: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
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

public struct AnyHTMLID: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
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

public struct AnyCSSVariable: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue.hasPrefix("--")
            ? rawValue
            : "--\(rawValue)"
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(value)
    }
}

public struct HTMLClass<Namespace>: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
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

    public var erased: AnyHTMLClass {
        AnyHTMLClass(rawValue)
    }
}

public struct HTMLID<Namespace>: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
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

    public var erased: AnyHTMLID {
        AnyHTMLID(rawValue)
    }
}

public struct CSSVariable<Namespace>: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue.hasPrefix("--")
            ? rawValue
            : "--\(rawValue)"
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(value)
    }

    public var erased: AnyCSSVariable {
        AnyCSSVariable(rawValue)
    }
}

public enum DOMSelectorTarget<Namespace>: Sendable, Hashable, Codable {
    case id(HTMLID<Namespace>)
    case `class`(HTMLClass<Namespace>)
    case raw(String)

    public var rawValue: String {
        switch self {
        case .id(let id):
            return "#\(id.rawValue)"

        case .class(let cls):
            return ".\(cls.rawValue)"

        case .raw(let value):
            return value
        }
    }
}

public enum DOMEvent: String, Sendable, CaseIterable {
    case click
    case input
    case change
    case submit
    case focus
    case blur
    case keydown
    case keyup
}
