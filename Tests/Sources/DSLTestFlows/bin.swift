import DSL
import Foundation
import Provenance
import Testing

private enum DSLTestFailure: Error {
    case failed
    case lowering
}

@main
struct DSLTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            DSLFlowSuite.suite,
            sink: reporter
        )
        let output = await reporter.rendered()
        if !output.isEmpty {
            print(output)
        }
        if result.isFailure {
            throw DSLTestFailure.failed
        }
    }
}

enum DSLFlowSuite {
    static let suite = TestSuite("dsl", title: "DSL") {
        Test("provenance-rules") { try provenanceRules() }
        Test("provenance-sentence") { try provenanceSentence() }
    }

    static let levi = ProvenancePerson(rawValue: "Levi")
    static let casper = ProvenancePerson(rawValue: "Casper")

    static func provenanceRules() throws {
        func violation(_ raw: Provenance.Raw) -> Provenance.Violation? {
            do {
                _ = try Provenance(raw)
                return nil
            } catch {
                return error
            }
        }

        let sessions = Provenance.Source.sessions(count: 14, years: 2025...2026)

        try Expect.equal(
            violation(.init(involvement: .derived, control: .instructed(by: levi), sources: [sessions], audience: .internal)),
            .clientSourcesNeedRedaction,
            "client sources need redaction"
        )
        try Expect.equal(
            violation(.init(involvement: .derived, control: .instructed(by: levi), sources: [sessions], redaction: .init(.pseudonymized), review: .reviewed(by: casper, on: "2026-11-12"), audience: .public)),
            .publicClientSourcesNeedAnonymization,
            "public client sources need anonymization"
        )
        try Expect.equal(
            violation(.init(involvement: .derived, control: .instructed(by: levi), sources: [sessions], redaction: .init(.aggregated, by: .automatic), review: .reviewed(by: casper, on: "2026-11-12"), audience: .public)),
            .publicAutomaticRedactionNeedsCheck,
            "public automatic redaction needs a check"
        )
        try Expect.equal(
            violation(.init(involvement: .drafted, control: .handGuided(by: levi), audience: .public)),
            .publicGeneratedTextNeedsReview,
            "public generated text needs review"
        )
        try Expect.equal(
            violation(.init(involvement: .drafted, control: .automatic, review: .reviewed(by: casper, on: "2026-11-12"), audience: .internal)),
            .unattendedGenerationNeedsTrace,
            "unattended generation needs a trace"
        )
        try Expect.equal(
            violation(.init(involvement: .assisted, control: .supervised(by: levi), trace: .init(sessions: ["540E0A9F-3C9C-4BE2-8A7A-61F8695EE1B8"], build: .init(commit: "abc", clean: false)), audience: .public)),
            .publicDirtyBuildNeedsAcknowledgement,
            "public dirty build needs acknowledgement"
        )
        try Expect.equal(
            violation(.init(involvement: .assisted, control: .supervised(by: levi), trace: .init(sessions: []), audience: .internal)),
            .traceNeedsSessions,
            "trace needs sessions"
        )
        try Expect.equal(
            violation(.init(involvement: .assisted, control: .handGuided(by: levi), audience: .public)),
            nil,
            "assisted, hand-guided text needs nothing more"
        )

        let internalDirty = try Provenance(
            .init(involvement: .assisted, control: .supervised(by: levi), trace: .init(sessions: ["540E0A9F-3C9C"], build: .init(commit: "abc", clean: false)), audience: .internal)
        )
        try Expect.true(internalDirty.isFromDirtyBuild, "internal dirty build is allowed and flagged")

    }

    static func provenanceSentence() throws {
        let provenance = try Provenance(
            .init(
                involvement: .drafted,
                control: .instructed(by: levi),
                sources: [.sessions(count: 14, years: 2025...2026), .literature],
                redaction: .init(.aggregated, by: .automaticChecked(by: casper)),
                review: .reviewed(by: casper, on: "2026-11-12"),
                trace: .init(sessions: ["540E0A9F-3C9C-4BE2-8A7A-61F8695EE1B8"], build: .init(commit: "0123456789abcdef", clean: true)),
                audience: .public
            )
        )

        try Expect.equal(
            provenance.sentence(.dutch),
            "Opgesteld met AI in opdracht van Levi, op basis van 14 sessietranscripten (2025–2026) en literatuur; geaggregeerd, nagelezen door Casper op 12-11-2026.",
            "dutch sentence"
        )
        try Expect.equal(
            provenance.sentence(.english),
            "Drafted with AI as instructed by Levi, based on 14 session transcripts (2025–2026) and literature; aggregated, reviewed by Casper on 2026-11-12.",
            "english sentence"
        )

        guard case .group(let role, _, .collection(let blocks)) = provenance.structuredContent(.english),
              role == .note,
              case .definitions(let details) = blocks.last
        else {
            throw DSLTestFailure.lowering
        }

        try Expect.equal(
            details.last?.description,
            .paragraph([.code("540E0A9F · build 0123456789")]),
            "trace shows the short session id and build"
        )

        let decoded = try JSONDecoder().decode(Provenance.self, from: JSONEncoder().encode(provenance))
        try Expect.equal(decoded, provenance, "codable round trip")

    }
}
