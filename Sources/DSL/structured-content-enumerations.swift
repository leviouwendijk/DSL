/// The document-enumeration pass (D9): one walk in tree order numbers
/// citations and footnotes on one shared counter (each occurrence gets the
/// next number, as `CitationResolver` does), gives headings and figures
/// anchors and numbers, and lowers citations and footnotes to
/// `noteReference`. A second walk fills every `listing` from those tables,
/// so a bibliography may come before its citations.
///
/// The content passed is the scope: an article, a section or a site.
public struct StructuredContentEnumerations:
    Sendable
{
    public struct Footnote:
        Sendable,
        Hashable
    {
        public let number: Int
        public let anchor: StructuredContent.AnchorKey
        public let content: StructuredContent
    }

    public struct Heading:
        Sendable,
        Hashable
    {
        public let level: Int
        public let anchor: StructuredContent.AnchorKey
        public let content: [StructuredContent.Inline]
        /// Section number by level, e.g. `[2, 1]` for 2.1.
        public let number: [Int]
    }

    public struct Figure:
        Sendable,
        Hashable
    {
        public let number: Int
        public let anchor: StructuredContent.AnchorKey
        public let caption: [StructuredContent.Inline]?
    }

    public struct Options:
        Sendable
    {
        /// The words before a figure's caption, per language.
        public var figureLabel: @Sendable (Int) -> [StructuredContent.Inline]
        /// Footnotes and citations with no listing in scope get one at the
        /// end, so their text isn't lost.
        public var appendMissingListings: Bool

        public init(
            figureLabel: @escaping @Sendable (Int) -> [StructuredContent.Inline] = {
                [.text("Figure \($0). ")]
            },
            appendMissingListings: Bool = true
        ) {
            self.figureLabel = figureLabel
            self.appendMissingListings = appendMissingListings
        }
    }

    public struct Resolved:
        Sendable
    {
        public let content: StructuredContent
        public let enumerations: StructuredContentEnumerations
    }

    public private(set) var citations = DocumentEnumeration<StructuredContent.CitationKey>()
    /// Per key, the occurrences that named locators, grouped by locator set.
    public private(set) var citationUses: [StructuredContent.CitationKey: [StructuredContent.NoteUse]] = [:]
    public private(set) var footnotes: [Footnote] = []
    public private(set) var headings: [Heading] = []
    public private(set) var figures: [Figure] = []

    private var occurrence = 0
    private var anchors: Set<String> = []
    private var headingCounters = [Int](repeating: 0, count: 6)
    private var listings: Set<StructuredContent.Listing> = []

    public static func anchor(
        citation key: StructuredContent.CitationKey
    ) -> StructuredContent.AnchorKey {
        .init(rawValue: "ref-" + key.rawValue)
    }

    public static func anchor(
        footnote number: Int
    ) -> StructuredContent.AnchorKey {
        .init(rawValue: "footnote-\(number)")
    }

    public static func resolve(
        _ content: StructuredContent,
        bibliography: some StructuredContentBibliographyProviding = StructuredContentKeyBibliography(),
        options: Options = .init()
    ) -> Resolved {
        var tables = StructuredContentEnumerations()
        let numbered = tables.number(content, options: options)
        var listed = tables.list(numbered, bibliography: bibliography)

        if options.appendMissingListings {
            var appended: [StructuredContent] = []

            if !tables.listings.contains(.footnotes),
               !tables.footnotes.isEmpty
            {
                appended.append(tables.listing(.footnotes, bibliography: bibliography))
            }

            if !tables.listings.contains(.bibliography),
               !tables.citations.isEmpty
            {
                appended.append(tables.listing(.bibliography, bibliography: bibliography))
            }

            if !appended.isEmpty {
                if case .collection(let children) = listed {
                    listed = .collection(children + appended)
                } else {
                    listed = .collection([listed] + appended)
                }
            }
        }

        return .init(
            content: listed,
            enumerations: tables
        )
    }
}

private extension StructuredContentEnumerations {
    // MARK: Pass 1: number in tree order

    mutating func number(
        _ content: StructuredContent,
        options: Options
    ) -> StructuredContent {
        switch content {
        case .collection(let children):
            return .collection(children.map { number($0, options: options) })

        case .paragraph(let inline):
            return .paragraph(number(inline))

        case .code,
             .image,
             .rule,
             .notes:
            return content

        case .quote(let inner, let attribution):
            let inner = number(inner, options: options)
            return .quote(inner, attribution: attribution.map { number($0) })

        case .list(let style, let items):
            return .list(style: style, items: items.map { number($0, options: options) })

        case .group(let role, let title, let inner):
            let title = title.map { number($0) }
            return .group(role: role, title: title, content: number(inner, options: options))

        case .table(let header, let rows):
            let header = header.map { number($0, options: options) }
            return .table(
                header: header,
                rows: rows.map { $0.map { number($0, options: options) } }
            )

        case .heading(let level, let anchor, let inline):
            let level = StructuredContentFallback.headingLevel(level)
            let anchor = claim(anchor?.rawValue ?? Self.slug(inline.map(\.plainText).joined()))
            let inline = number(inline)

            headingCounters[level - 1] += 1
            for deeper in level..<6 {
                headingCounters[deeper] = 0
            }

            headings.append(
                .init(
                    level: level,
                    anchor: anchor,
                    content: inline,
                    number: Array(headingCounters[0..<level].drop { $0 == 0 })
                )
            )
            return .heading(level: level, anchor: anchor, content: inline)

        case .figure(let anchor, let inner, let caption):
            let figureNumber = figures.count + 1
            let anchor = claim(anchor?.rawValue ?? "figure-\(figureNumber)")
            let inner = number(inner, options: options)
            let caption = caption.map { number($0) }

            figures.append(
                .init(
                    number: figureNumber,
                    anchor: anchor,
                    caption: caption
                )
            )
            return .figure(
                anchor: anchor,
                content: inner,
                caption: options.figureLabel(figureNumber) + (caption ?? [])
            )

        case .verse(let lines):
            return .verse(lines.map { number($0) })

        case .definitions(let definitions):
            return .definitions(
                definitions.map {
                    let term = number($0.term)
                    return .init(term: term, description: number($0.description, options: options))
                }
            )

        case .listing(let listing):
            listings.insert(listing)
            return content

        case .native(let target, let key, let fallback):
            return .native(target: target, key: key, fallback: number(fallback, options: options))
        }
    }

    mutating func number(
        _ inline: [StructuredContent.Inline]
    ) -> [StructuredContent.Inline] {
        inline.map { number($0) }
    }

    mutating func number(
        _ inline: StructuredContent.Inline
    ) -> StructuredContent.Inline {
        switch inline {
        case .text,
             .code,
             .noteReference:
            return inline

        case .emphasis(let content):
            return .emphasis(number(content))

        case .strong(let content):
            return .strong(number(content))

        case .link(let target, let content):
            return .link(target: target, content: number(content))

        case .citation(let key, let locators):
            occurrence += 1
            citations.record(key, occurrence: occurrence)

            if !locators.isEmpty {
                var uses = citationUses[key, default: []]
                if let index = uses.firstIndex(where: { $0.locators == locators }) {
                    uses[index] = .init(
                        pointers: uses[index].pointers + [occurrence],
                        locators: locators
                    )
                } else {
                    uses.append(.init(pointers: [occurrence], locators: locators))
                }
                citationUses[key] = uses
            }

            return .noteReference(
                number: occurrence,
                anchor: Self.anchor(citation: key)
            )

        case .footnote(let content):
            occurrence += 1
            let anchor = Self.anchor(footnote: occurrence)
            footnotes.append(
                .init(
                    number: occurrence,
                    anchor: anchor,
                    content: content
                )
            )
            return .noteReference(
                number: occurrence,
                anchor: anchor
            )
        }
    }

    /// `preferred`, or `preferred-2`, `-3`, … when taken.
    mutating func claim(
        _ preferred: String
    ) -> StructuredContent.AnchorKey {
        var candidate = preferred
        var suffix = 2

        while anchors.contains(candidate) {
            candidate = preferred + "-\(suffix)"
            suffix += 1
        }

        anchors.insert(candidate)
        return .init(rawValue: candidate)
    }

    /// Lowercase letters and digits; runs of anything else become one `-`.
    static func slug(
        _ text: String
    ) -> String {
        var result = ""
        var pendingDash = false

        for character in text.lowercased() {
            if character.isLetter || character.isNumber {
                if pendingDash, !result.isEmpty {
                    result.append("-")
                }
                pendingDash = false
                result.append(character)
            } else {
                pendingDash = true
            }
        }

        return result.isEmpty ? "section" : result
    }

    // MARK: Pass 2: fill listings

    func list(
        _ content: StructuredContent,
        bibliography: some StructuredContentBibliographyProviding
    ) -> StructuredContent {
        switch content {
        case .listing(let listing):
            return self.listing(listing, bibliography: bibliography)

        case .collection(let children):
            return .collection(children.map { list($0, bibliography: bibliography) })

        case .quote(let inner, let attribution):
            return .quote(list(inner, bibliography: bibliography), attribution: attribution)

        case .list(let style, let items):
            return .list(style: style, items: items.map { list($0, bibliography: bibliography) })

        case .group(let role, let title, let inner):
            return .group(role: role, title: title, content: list(inner, bibliography: bibliography))

        case .table(let header, let rows):
            return .table(
                header: header.map { list($0, bibliography: bibliography) },
                rows: rows.map { $0.map { list($0, bibliography: bibliography) } }
            )

        case .figure(let anchor, let inner, let caption):
            return .figure(anchor: anchor, content: list(inner, bibliography: bibliography), caption: caption)

        case .definitions(let definitions):
            return .definitions(
                definitions.map {
                    .init(term: $0.term, description: list($0.description, bibliography: bibliography))
                }
            )

        case .native(let target, let key, let fallback):
            return .native(target: target, key: key, fallback: list(fallback, bibliography: bibliography))

        case .paragraph,
             .code,
             .heading,
             .image,
             .verse,
             .rule,
             .notes:
            return content
        }
    }

    func listing(
        _ listing: StructuredContent.Listing,
        bibliography: some StructuredContentBibliographyProviding
    ) -> StructuredContent {
        switch listing {
        case .footnotes:
            guard !footnotes.isEmpty else { return .collection([]) }
            return .notes(
                footnotes.map {
                    .init(anchor: $0.anchor, pointers: [$0.number], content: $0.content)
                }
            )

        case .bibliography:
            guard !citations.isEmpty else { return .collection([]) }
            return .notes(
                citations.entries.map { entry in
                    .init(
                        anchor: Self.anchor(citation: entry.key),
                        pointers: entry.occurrences,
                        content: bibliography.entry(entry.key)
                            ?? .paragraph([.text(entry.key.rawValue)]),
                        uses: citationUses[entry.key] ?? []
                    )
                }
            )

        case .contents:
            guard !headings.isEmpty else { return .collection([]) }
            return contents(headings[...])
        }
    }

    /// Nested lists by level: each heading at the shallowest level is an
    /// item; deeper headings after it are its children.
    func contents(
        _ headings: ArraySlice<Heading>
    ) -> StructuredContent {
        let level = headings.map(\.level).min() ?? 1
        var items: [StructuredContent] = []
        var index = headings.startIndex

        while index < headings.endIndex {
            let heading = headings[index]
            var end = headings.index(after: index)

            while end < headings.endIndex, headings[end].level > level {
                end = headings.index(after: end)
            }

            let link = StructuredContent.paragraph([
                .link(target: .anchor(heading.anchor), content: heading.content),
            ])
            let children = headings[headings.index(after: index)..<end]

            items.append(
                children.isEmpty ? link : .collection([link, contents(children)])
            )
            index = end
        }

        return .list(style: .unordered, items: items)
    }
}
