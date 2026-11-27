import DSL

public extension Provenance {
    enum Language:
        String,
        Sendable,
        Codable,
        Hashable
    {
        case english
        case dutch
    }

    /// The headline: what the AI did, who steered it, what it draws on,
    /// redaction and review. "Drafted with AI as instructed by Levi, based on
    /// 14 session transcripts (2025–2026) and literature; aggregated,
    /// reviewed by Casper on 2026-11-12."
    func sentence(
        _ language: Language
    ) -> String {
        let words = Words(language: language)
        var head = words.involvement(involvement) + " " + words.control(control)

        if !sources.isEmpty {
            head += ", " + words.basedOn + " " + words.list(sources.map(words.source))
        }

        var tail: [String] = []

        if redaction.level != .none {
            tail.append(words.redaction(redaction.level))
        }

        tail.append(words.review(review))

        return head + "; " + tail.joined(separator: ", ") + "."
    }

    /// The details behind the headline: control, redaction method, trace.
    func details(
        _ language: Language
    ) -> [StructuredContent.Definition] {
        let words = Words(language: language)
        var details: [StructuredContent.Definition] = [
            .init(
                term: [.text(words.controlTerm)],
                description: .paragraph([.text(words.controlDetail(control))])
            ),
        ]

        if let method = redaction.method {
            details.append(
                .init(
                    term: [.text(words.redactionTerm)],
                    description: .paragraph([.text(words.redactionMethod(method))])
                )
            )
        }

        if let trace {
            var text = trace.shortSessions.joined(separator: ", ")

            if let build = trace.build {
                text += " · " + words.build + " " + String(build.commit.prefix(10))
                    + (build.clean ? "" : " (" + words.dirty + ")")
            }

            details.append(
                .init(
                    term: [.text(words.traceTerm)],
                    description: .paragraph([.code(text)])
                )
            )
        }

        return details
    }

    /// A note with the sentence and its details: the lowering for Markdown,
    /// the terminal and reports. The HTML card is its own component.
    func structuredContent(
        _ language: Language
    ) -> StructuredContent {
        .group(
            role: .note,
            title: [.text(Words(language: language).title)],
            content: .collection([
                .paragraph([.text(sentence(language))]),
                .definitions(details(language)),
            ])
        )
    }
}

private extension Provenance {
    struct Words {
        let language: Language

        var dutch: Bool { language == .dutch }

        var title: String { dutch ? "Totstandkoming" : "How this was made" }
        var basedOn: String { dutch ? "op basis van" : "based on" }
        var controlTerm: String { dutch ? "Sturing" : "Control" }
        var redactionTerm: String { dutch ? "Redactie" : "Redaction" }
        var traceTerm: String { dutch ? "Herkomst" : "Trace" }
        var build: String { dutch ? "build" : "build" }
        var dirty: String { dutch ? "niet-gecommitte wijzigingen" : "uncommitted changes" }

        func involvement(_ involvement: Involvement) -> String {
            switch involvement {
            case .assisted: dutch ? "Bewerkt met hulp van AI" : "Edited with AI help"
            case .drafted: dutch ? "Opgesteld met AI" : "Drafted with AI"
            case .derived: dutch ? "Met AI afgeleid uit bronmateriaal" : "Derived with AI from source material"
            case .translated: dutch ? "Vertaald met AI" : "Translated with AI"
            }
        }

        func control(_ control: Control) -> String {
            switch control {
            case .handGuided(let person): (dutch ? "begeleid door " : "guided by ") + person.rawValue
            case .instructed(let person): (dutch ? "in opdracht van " : "as instructed by ") + person.rawValue
            case .supervised(let person): (dutch ? "onder toezicht van " : "supervised by ") + person.rawValue
            case .automatic: dutch ? "automatisch" : "automatically"
            }
        }

        func controlDetail(_ control: Control) -> String {
            switch control {
            case .handGuided:
                dutch ? "Stap voor stap gestuurd; een persoon koos wat bleef." : "Steered turn by turn; a person chose what to keep."
            case .instructed:
                dutch ? "Een persoon gaf de opdracht en bewerkte het resultaat." : "A person briefed this piece and edited the result."
            case .supervised:
                dutch ? "Een vaste werkwijze; een persoon keurde het resultaat goed." : "A standing workflow; a person approved the output."
            case .automatic:
                dutch ? "Gegenereerd zonder tussenkomst vóór de review." : "Generated with no person involved before review."
            }
        }

        func source(_ source: Source) -> String {
            let noun: String
            switch source.kind {
            case .sessions: noun = dutch ? "sessietranscripten" : "session transcripts"
            case .calls: noun = dutch ? "gesprekken" : "calls"
            case .notes: noun = dutch ? "interne notities" : "internal notes"
            case .experience: noun = dutch ? "trainerservaring" : "trainer experience"
            case .literature: noun = dutch ? "literatuur" : "literature"
            }

            var text = source.count.map { "\($0) " + noun } ?? noun

            if let years = source.years {
                text += years.lowerBound == years.upperBound
                    ? " (\(years.lowerBound))"
                    : " (\(years.lowerBound)–\(years.upperBound))"
            }

            return text
        }

        func redaction(_ level: Redaction.Level) -> String {
            switch level {
            case .none: ""
            case .pseudonymized: dutch ? "gepseudonimiseerd" : "pseudonymized"
            case .anonymized: dutch ? "geanonimiseerd" : "anonymized"
            case .aggregated: dutch ? "geaggregeerd" : "aggregated"
            }
        }

        func redactionMethod(_ method: Redaction.Method) -> String {
            switch method {
            case .manual(let person): (dutch ? "Met de hand, door " : "By hand, by ") + person.rawValue
            case .automatic: dutch ? "Automatisch" : "Automatically"
            case .automaticChecked(let person): (dutch ? "Automatisch, gecontroleerd door " : "Automatically, checked by ") + person.rawValue
            }
        }

        func review(_ review: Review) -> String {
            switch review {
            case .reviewed(let person, let date):
                dutch
                    ? "nagelezen door \(person.rawValue) op \(dutchDate(date))"
                    : "reviewed by \(person.rawValue) on \(date)"
            case .unreviewed:
                dutch ? "niet nagelezen" : "not reviewed"
            }
        }

        /// `2026-11-12` → `12-11-2026`; anything else unchanged.
        func dutchDate(_ date: String) -> String {
            let parts = date.split(separator: "-")
            guard parts.count == 3 else { return date }
            return [parts[2], parts[1], parts[0]].joined(separator: "-")
        }

        func list(_ items: [String]) -> String {
            guard items.count > 1 else { return items.first ?? "" }
            return items.dropLast().joined(separator: ", ") + (dutch ? " en " : " and ") + items[items.count - 1]
        }
    }
}
