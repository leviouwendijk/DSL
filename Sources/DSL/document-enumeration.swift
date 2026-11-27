/// Keys in order of first appearance, with every occurrence's number. The
/// counter belongs to the caller, so several enumerations can share one
/// (citations and footnotes do).
public struct DocumentEnumeration<Key: Hashable & Sendable>:
    Sendable
{
    public struct Entry:
        Sendable
    {
        public let key: Key
        /// Occurrence numbers, in order.
        public fileprivate(set) var occurrences: [Int]
    }

    public private(set) var entries: [Entry] = []
    private var positions: [Key: Int] = [:]

    public init() {}

    /// Records an occurrence of `key` numbered `occurrence`; true when it is
    /// the key's first.
    @discardableResult
    public mutating func record(
        _ key: Key,
        occurrence: Int
    ) -> Bool {
        if let position = positions[key] {
            entries[position].occurrences.append(occurrence)
            return false
        }

        positions[key] = entries.count
        entries.append(
            .init(
                key: key,
                occurrences: [occurrence]
            )
        )
        return true
    }

    public func entry(
        _ key: Key
    ) -> Entry? {
        positions[key].map { entries[$0] }
    }

    /// 1-based position of first appearance.
    public func position(
        of key: Key
    ) -> Int? {
        positions[key].map { $0 + 1 }
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }
}

/// Supplies the printed entry for a citation key (a reference library).
public protocol StructuredContentBibliographyProviding:
    Sendable
{
    func entry(
        _ key: StructuredContent.CitationKey
    ) -> StructuredContent?
}

/// No library: entries print their key.
public struct StructuredContentKeyBibliography:
    StructuredContentBibliographyProviding
{
    public init() {}

    public func entry(
        _ key: StructuredContent.CitationKey
    ) -> StructuredContent? {
        nil
    }
}
