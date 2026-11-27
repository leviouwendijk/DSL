/// Role → style tokens, per colour scheme. Targets lower the same theme:
/// CSS to custom properties, Terminal to SGR styles. Content carries roles;
/// the theme decides how a role looks.
public struct Theme:
    Sendable,
    Hashable
{
    public typealias Role = StructuredContent.Role

    public enum Scheme:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case light
        case dark
    }

    public struct Style:
        Sendable,
        Codable,
        Hashable
    {
        public enum Weight:
            String,
            Sendable,
            Codable,
            Hashable
        {
            /// Lighter than the text around it (`dim` in a terminal).
            case light
            case regular
            case bold
        }

        public var foreground: ThemeColor?
        public var background: ThemeColor?
        public var weight: Weight?
        public var italic: Bool?
        public var underline: Bool?
        /// Space around a block, in steps: a blank row in a terminal, a line
        /// height in CSS.
        public var spacing: Int?
        /// Indentation of a block's content, in steps: a column in a
        /// terminal, `1ch` in CSS.
        public var indent: Int?

        public init(
            foreground: ThemeColor? = nil,
            background: ThemeColor? = nil,
            weight: Weight? = nil,
            italic: Bool? = nil,
            underline: Bool? = nil,
            spacing: Int? = nil,
            indent: Int? = nil
        ) {
            self.foreground = foreground
            self.background = background
            self.weight = weight
            self.italic = italic
            self.underline = underline
            self.spacing = spacing.map { max(0, $0) }
            self.indent = indent.map { max(0, $0) }
        }

        /// `overlay`'s tokens where it sets them, these elsewhere.
        public func merging(
            _ overlay: Style
        ) -> Style {
            .init(
                foreground: overlay.foreground ?? foreground,
                background: overlay.background ?? background,
                weight: overlay.weight ?? weight,
                italic: overlay.italic ?? italic,
                underline: overlay.underline ?? underline,
                spacing: overlay.spacing ?? spacing,
                indent: overlay.indent ?? indent
            )
        }
    }

    /// The styles of the light scheme, and the base of the dark one.
    public var light: [Role: Style]
    /// Overrides on top of `light` for the dark scheme (usually colours only).
    public var dark: [Role: Style]

    public init(
        light: [Role: Style] = [:],
        dark: [Role: Style] = [:]
    ) {
        self.light = light
        self.dark = dark
    }

    /// The role's style in `scheme`; nil when the theme doesn't style it.
    public func style(
        _ role: Role,
        scheme: Scheme
    ) -> Style? {
        switch scheme {
        case .light:
            return light[role]
        case .dark:
            switch (light[role], dark[role]) {
            case (nil, nil):
                return nil
            case (let base?, nil):
                return base
            case (nil, let overlay?):
                return overlay
            case (let base?, let overlay?):
                return base.merging(overlay)
            }
        }
    }

    /// Every styled role, in name order.
    public var roles: [Role] {
        Set(light.keys)
            .union(dark.keys)
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// The look the terminal renderer had before themes: code and secondary
    /// text dimmed, emphasis italic, strong and headings bold, links
    /// underlined. No colours, so it reads in either scheme.
    public static var standard: Self {
        .init(
            light: [
                .code: .init(weight: .light),
                .emphasis: .init(italic: true),
                .strong: .init(weight: .bold),
                .heading: .init(weight: .bold),
                .link: .init(underline: true),
                .quote: .init(weight: .light),
                .caption: .init(weight: .light),
                .muted: .init(weight: .light),
                .rule: .init(weight: .light),
            ]
        )
    }
}

extension Theme: Codable {
    private enum CodingKeys: String, CodingKey {
        case light
        case dark
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func styles(_ key: CodingKeys) throws -> [Role: Style] {
            let named = try container.decodeIfPresent([String: Style].self, forKey: key) ?? [:]
            return Dictionary(
                uniqueKeysWithValues: named.map { (Role(rawValue: $0.key), $0.value) }
            )
        }

        self.init(
            light: try styles(.light),
            dark: try styles(.dark)
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        func named(_ styles: [Role: Style]) -> [String: Style] {
            Dictionary(
                uniqueKeysWithValues: styles.map { ($0.key.rawValue, $0.value) }
            )
        }

        try container.encode(named(light), forKey: .light)

        if !dark.isEmpty {
            try container.encode(named(dark), forKey: .dark)
        }
    }
}

/// Roles every target styles, beside the group roles (`note`, `tip`, …).
public extension StructuredContent.Role {
    static var body: Self { .init(rawValue: "body") }
    static var heading: Self { .init(rawValue: "heading") }
    static var emphasis: Self { .init(rawValue: "emphasis") }
    static var strong: Self { .init(rawValue: "strong") }
    static var code: Self { .init(rawValue: "code") }
    static var link: Self { .init(rawValue: "link") }
    /// A quote's gutter or border.
    static var quote: Self { .init(rawValue: "quote") }
    /// Figure captions and quote attributions.
    static var caption: Self { .init(rawValue: "caption") }
    /// Secondary text: metadata lines, dates.
    static var muted: Self { .init(rawValue: "muted") }
    /// The one accent colour.
    static var accent: Self { .init(rawValue: "accent") }
    static var rule: Self { .init(rawValue: "rule") }
}
