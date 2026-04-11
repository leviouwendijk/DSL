public struct BlockSelectorAPI<Namespace>: Sendable {
    public let block: String

    public init(
        block: String
    ) {
        self.block = block
    }

    public var root: HTMLClass<Namespace> {
        HTMLClass(block)
    }

    public func element(
        _ name: String
    ) -> HTMLClass<Namespace> {
        HTMLClass("\(block)__\(name)")
    }

    public func modifier(
        _ name: String
    ) -> HTMLClass<Namespace> {
        HTMLClass("\(block)--\(name)")
    }

    public func id(
        _ name: String? = nil
    ) -> HTMLID<Namespace> {
        if let name {
            return HTMLID("\(block)-\(name)")
        } else {
            return HTMLID(block)
        }
    }

    public func variable(
        _ name: String
    ) -> CSSVariable<Namespace> {
        CSSVariable("--\(block)-\(name)")
    }

    public func target(
        _ value: HTMLClass<Namespace>
    ) -> DOMSelectorTarget<Namespace> {
        .class(value)
    }

    public func target(
        _ value: HTMLID<Namespace>
    ) -> DOMSelectorTarget<Namespace> {
        .id(value)
    }
}
