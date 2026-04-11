public protocol BlockSelectorProviding {
    associatedtype SelectorNamespace

    static var selectorBlock: String { get }
}

public extension BlockSelectorProviding {
    static var selectors: BlockSelectorAPI<SelectorNamespace> {
        BlockSelectorAPI(
            block: selectorBlock
        )
    }
}
