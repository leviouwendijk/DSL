/// A person named in provenance (who steered, checked or reviewed).
/// Until identity lands this is a display name; later a sysid.
public struct ProvenancePerson:
    RawRepresentable,
    Sendable,
    Codable,
    Hashable
{
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public extension Provenance {
    /// What the AI did.
    enum Involvement:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        /// A person wrote it; AI edited.
        case assisted
        /// AI wrote it; a person edited.
        case drafted
        /// Interpreted from source data (transcripts) and summarized.
        case derived
        case translated

        /// The AI wrote the text, rather than editing a person's.
        public var isGenerated: Bool {
            self == .drafted || self == .derived
        }
    }

    /// How much a person steered the generation.
    enum Control:
        Sendable,
        Codable,
        Hashable
    {
        /// Interactive: a person steered turn by turn and chose what to keep.
        case handGuided(by: ProvenancePerson)
        /// A person briefed this piece; the agent ran it, the person edited.
        case instructed(by: ProvenancePerson)
        /// A standing workflow; a person approved or rejected the output.
        case supervised(by: ProvenancePerson)
        /// A pipeline with no person before review.
        case automatic

        /// No person shaped the output as it was made.
        public var isUnattended: Bool {
            switch self {
            case .supervised,
                 .automatic:
                return true
            case .handGuided,
                 .instructed:
                return false
            }
        }

        public var person: ProvenancePerson? {
            switch self {
            case .handGuided(let person),
                 .instructed(let person),
                 .supervised(let person):
                return person
            case .automatic:
                return nil
            }
        }
    }

    /// A kind of material the text draws on. Listed, never shared.
    struct Source:
        Sendable,
        Codable,
        Hashable
    {
        public enum Kind:
            String,
            Sendable,
            Codable,
            Hashable
        {
            /// Training session transcripts.
            case sessions
            /// Sales and client calls.
            case calls
            /// Internal protocols and notes.
            case notes
            /// Trainer experience.
            case experience
            /// The bibliography (D9): linked, not repeated.
            case literature

            /// Material from clients, which needs redaction.
            public var isClientDerived: Bool {
                self == .sessions || self == .calls
            }
        }

        public let kind: Kind
        public let count: Int?
        /// Years covered, e.g. 2025...2026.
        public let years: ClosedRange<Int>?
        /// Ids that resolve only in the internal knowledge base.
        public let internalIDs: [String]

        public init(
            _ kind: Kind,
            count: Int? = nil,
            years: ClosedRange<Int>? = nil,
            internalIDs: [String] = []
        ) {
            self.kind = kind
            self.count = count
            self.years = years
            self.internalIDs = internalIDs
        }

        public static func sessions(count: Int? = nil, years: ClosedRange<Int>? = nil) -> Self {
            .init(.sessions, count: count, years: years)
        }

        public static func calls(count: Int? = nil, years: ClosedRange<Int>? = nil) -> Self {
            .init(.calls, count: count, years: years)
        }

        public static var literature: Self {
            .init(.literature)
        }
    }

    struct Redaction:
        Sendable,
        Codable,
        Hashable
    {
        public enum Level:
            Int,
            Sendable,
            Codable,
            Hashable,
            Comparable
        {
            /// Own writing without client data.
            case none
            case pseudonymized
            case anonymized
            /// No single case recognizable.
            case aggregated

            public static func < (
                lhs: Self,
                rhs: Self
            ) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }

        public enum Method:
            Sendable,
            Codable,
            Hashable
        {
            case manual(by: ProvenancePerson)
            case automatic
            /// Automatic, then checked by a person.
            case automaticChecked(by: ProvenancePerson)
        }

        public let level: Level
        public let method: Method?

        public init(
            _ level: Level,
            by method: Method? = nil
        ) {
            self.level = level
            self.method = method
        }

        public static var none: Self {
            .init(.none)
        }
    }

    enum Review:
        Sendable,
        Codable,
        Hashable
    {
        /// `on` is an ISO date (`2026-11-12`).
        case reviewed(by: ProvenancePerson, on: String)
        case unreviewed
    }

    /// Where the text is published; public content carries stricter rules.
    enum Audience:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case `internal`
        case `public`
    }
}

/// The record that produced the text: one or more Agentic sessions.
public struct GenerationTrace:
    Sendable,
    Codable,
    Hashable
{
    /// The harness build that ran the sessions.
    public struct Build:
        Sendable,
        Codable,
        Hashable
    {
        public let commit: String
        /// No uncommitted changes.
        public let clean: Bool

        public init(
            commit: String,
            clean: Bool
        ) {
            self.commit = commit
            self.clean = clean
        }
    }

    /// Full session UUIDs, in order.
    public let sessions: [String]
    /// A digest of the archived logs (`sha256:…`).
    public let digest: String?
    public let build: Build?
    /// Public content from a build with uncommitted changes was accepted
    /// deliberately.
    public let acknowledgesDirtyBuild: Bool

    public init(
        sessions: [String],
        digest: String? = nil,
        build: Build? = nil,
        acknowledgesDirtyBuild: Bool = false
    ) {
        self.sessions = sessions
        self.digest = digest
        self.build = build
        self.acknowledgesDirtyBuild = acknowledgesDirtyBuild
    }

    /// The first 8 characters of each session id, for display.
    public var shortSessions: [String] {
        sessions.map { String($0.prefix(8)) }
    }
}
