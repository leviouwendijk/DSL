/// Prose with inline structure written as one string:
///
/// ```swift
/// .prose("Attention is \(em: "not") effort.\(note: "A footnote.")")
/// ```
///
/// Libraries add interpolations for their own symbols (References adds
/// `\(cite: Library.key, at: .page("12"))`), so every mark stays typed.
public struct InlineText:
    Sendable,
    Hashable,
    ExpressibleByStringInterpolation
{
    public var inlines: [StructuredContent.Inline]

    public init(
        _ inlines: [StructuredContent.Inline]
    ) {
        self.inlines = inlines
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(value.isEmpty ? [] : [.text(value)])
    }

    public init(
        stringInterpolation: StringInterpolation
    ) {
        self.init(stringInterpolation.inlines)
    }

    public struct StringInterpolation:
        StringInterpolationProtocol
    {
        public private(set) var inlines: [StructuredContent.Inline] = []

        public init(
            literalCapacity: Int,
            interpolationCount: Int
        ) {
            inlines.reserveCapacity(interpolationCount * 2 + 1)
        }

        public mutating func appendLiteral(
            _ literal: String
        ) {
            appendText(literal)
        }

        public mutating func appendInterpolation(
            _ inline: StructuredContent.Inline
        ) {
            if case .text(let text) = inline {
                appendText(text)
            } else {
                inlines.append(inline)
            }
        }

        public mutating func appendInterpolation(
            _ text: InlineText
        ) {
            text.inlines.forEach { appendInterpolation($0) }
        }

        /// Plain text, e.g. a value computed elsewhere.
        public mutating func appendInterpolation(
            _ text: String
        ) {
            appendText(text)
        }

        public mutating func appendInterpolation(
            em text: InlineText
        ) {
            inlines.append(.emphasis(text.inlines))
        }

        public mutating func appendInterpolation(
            strong text: InlineText
        ) {
            inlines.append(.strong(text.inlines))
        }

        public mutating func appendInterpolation(
            code text: String
        ) {
            inlines.append(.code(text))
        }

        public mutating func appendInterpolation(
            link text: InlineText,
            to target: StructuredContent.LinkTarget
        ) {
            inlines.append(.link(target: target, content: text.inlines))
        }

        /// A footnote at this point.
        public mutating func appendInterpolation(
            note text: InlineText
        ) {
            inlines.append(.footnote(.paragraph(text.inlines)))
        }

        public mutating func appendInterpolation(
            note content: StructuredContent
        ) {
            inlines.append(.footnote(content))
        }

        /// A citation by key; reference libraries add typed overloads.
        public mutating func appendInterpolation(
            cite key: StructuredContent.CitationKey,
            at locators: ReferenceLocator...
        ) {
            inlines.append(.citation(key: key, locators: locators))
        }

        private mutating func appendText(
            _ text: String
        ) {
            guard !text.isEmpty else { return }

            if case .text(let existing) = inlines.last {
                inlines[inlines.count - 1] = .text(existing + text)
            } else {
                inlines.append(.text(text))
            }
        }
    }
}

public extension StructuredContent {
    /// A paragraph written as `InlineText`.
    static func prose(
        _ text: InlineText
    ) -> StructuredContent {
        .paragraph(text.inlines)
    }
}
