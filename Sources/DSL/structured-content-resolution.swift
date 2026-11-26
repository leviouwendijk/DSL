/// Supplies URLs for the symbols a renderer can't resolve on its own: pages
/// (a route table) and assets (a manifest).
public protocol StructuredContentURLResolving:
    Sendable
{
    func url(
        page: StructuredContent.PageKey,
        anchor: StructuredContent.AnchorKey?
    ) -> String?

    func url(
        asset: StructuredContent.AssetKey
    ) -> String?
}

public extension StructuredContentURLResolving {
    /// External URLs and in-document anchors resolve without a table.
    func url(
        _ target: StructuredContent.LinkTarget
    ) -> String? {
        switch target {
        case .external(let url):
            return url
        case .anchor(let anchor):
            return "#" + anchor.rawValue
        case .page(let page, let anchor):
            return url(
                page: page,
                anchor: anchor
            )
        case .asset(let asset):
            return url(
                asset: asset
            )
        }
    }

    func url(
        _ source: StructuredContent.ImageSource
    ) -> String? {
        switch source {
        case .external(let url):
            return url
        case .asset(let asset):
            return url(
                asset: asset
            )
        }
    }
}

/// Page and asset URLs from fixed tables. Empty, it resolves only what needs
/// no table (external URLs and anchors).
public struct StructuredContentURLTable:
    StructuredContentURLResolving,
    Hashable
{
    public var pages: [StructuredContent.PageKey: String]
    public var assets: [StructuredContent.AssetKey: String]

    public init(
        pages: [StructuredContent.PageKey: String] = [:],
        assets: [StructuredContent.AssetKey: String] = [:]
    ) {
        self.pages = pages
        self.assets = assets
    }

    public func url(
        page: StructuredContent.PageKey,
        anchor: StructuredContent.AnchorKey?
    ) -> String? {
        guard let base = pages[page] else {
            return nil
        }

        guard let anchor else {
            return base
        }

        return base + "#" + anchor.rawValue
    }

    public func url(
        asset: StructuredContent.AssetKey
    ) -> String? {
        assets[asset]
    }
}
