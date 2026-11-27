import Primitives

/// How a text was made: what the AI did, how much a person steered it, what
/// it draws on, how client material was redacted, who reviewed it, and the
/// record that produced it. A value exists only when the publication rules
/// hold (see `Violation`).
public struct Provenance:
    CodableInvariant,
    Sendable,
    Hashable
{
    public struct Raw:
        Sendable,
        Codable,
        Hashable
    {
        public var involvement: Involvement
        public var control: Control
        public var sources: [Source]
        public var redaction: Redaction
        public var review: Review
        public var trace: GenerationTrace?
        public var audience: Audience

        public init(
            involvement: Involvement,
            control: Control,
            sources: [Source] = [],
            redaction: Redaction = .none,
            review: Review = .unreviewed,
            trace: GenerationTrace? = nil,
            audience: Audience
        ) {
            self.involvement = involvement
            self.control = control
            self.sources = sources
            self.redaction = redaction
            self.review = review
            self.trace = trace
            self.audience = audience
        }
    }

    public enum Violation:
        Swift.Error,
        Sendable,
        Hashable
    {
        /// Sessions or calls need at least pseudonymization.
        case clientSourcesNeedRedaction
        /// Published client material must be anonymized or aggregated.
        case publicClientSourcesNeedAnonymization
        /// Drafted or derived text needs a review before it is published.
        case publicGeneratedTextNeedsReview
        /// Supervised or automatic generation needs a trace.
        case unattendedGenerationNeedsTrace
        /// Automatically redacted client material needs a person's check
        /// before it is published.
        case publicAutomaticRedactionNeedsCheck
        /// Public text from a build with uncommitted changes needs an
        /// explicit acknowledgement.
        case publicDirtyBuildNeedsAcknowledgement
        /// A trace names no session, or an empty one.
        case traceNeedsSessions
    }

    public let raw: Raw

    public init(
        _ raw: Raw
    ) throws(Violation) {
        let clientDerived = raw.sources.contains { $0.kind.isClientDerived }
        let isPublic = raw.audience == .public

        if clientDerived {
            guard raw.redaction.level >= .pseudonymized else {
                throw .clientSourcesNeedRedaction
            }

            if isPublic {
                guard raw.redaction.level >= .anonymized else {
                    throw .publicClientSourcesNeedAnonymization
                }

                if case .automatic = raw.redaction.method {
                    throw .publicAutomaticRedactionNeedsCheck
                }
            }
        }

        if isPublic,
           raw.involvement.isGenerated,
           raw.review == .unreviewed
        {
            throw .publicGeneratedTextNeedsReview
        }

        if let trace = raw.trace {
            guard !trace.sessions.isEmpty,
                  !trace.sessions.contains(where: \.isEmpty)
            else {
                throw .traceNeedsSessions
            }

            if isPublic,
               trace.build?.clean == false,
               !trace.acknowledgesDirtyBuild
            {
                throw .publicDirtyBuildNeedsAcknowledgement
            }
        } else if raw.control.isUnattended {
            throw .unattendedGenerationNeedsTrace
        }

        self.raw = raw
    }

    public var involvement: Involvement { raw.involvement }
    public var control: Control { raw.control }
    public var sources: [Source] { raw.sources }
    public var redaction: Redaction { raw.redaction }
    public var review: Review { raw.review }
    public var trace: GenerationTrace? { raw.trace }
    public var audience: Audience { raw.audience }

    /// Internal text from a build with uncommitted changes: allowed, flagged.
    public var isFromDirtyBuild: Bool {
        raw.trace?.build?.clean == false
    }
}
